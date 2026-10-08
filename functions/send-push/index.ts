// 아직 안 보낸 알림(notifications.pushed_at 이 빈 행)을 그 사용자의 아이폰에 APNs 푸시로 보낸다. DB 트리거(pg_net)와 1분 크론이 부른다.
// APNs 코드는 VIBI challenge-push 와 같다(같은 Apple 팀의 APNs 키를 쓴다). 공개 엔드포인트라 notify-admin 과 같은 공유 시크릿으로 막는다.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TOPIC = "app.massa.hanoi";
const NOTIFY_SECRET = Deno.env.get("NOTIFY_SECRET") ?? "";
const json = (o: unknown, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { "Content-Type": "application/json" } });

function b64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
// .env 에는 키가 한 줄로 들어 있고 줄바꿈이 글자 그대로의 \n 으로 적혀 있어서 그것도 지운다.
function pemToDer(pem: string): Uint8Array {
  const body = pem.replace(/\\n/g, "").replace(/-----BEGIN [^-]+-----/g, "").replace(/-----END [^-]+-----/g, "").replace(/\s+/g, "");
  const bin = atob(body);
  const der = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) der[i] = bin.charCodeAt(i);
  return der;
}

// APNs 토큰은 1시간 유효하고 20분보다 잦게 만들면 안 된다 → 인스턴스가 살아 있는 동안 30분 캐시
let apnsJwt: { token: string; at: number } | null = null;
async function getApnsJwt(): Promise<string | null> {
  const teamId = Deno.env.get("APPLE_TEAM_ID");
  const keyId = Deno.env.get("APNS_KEY_ID");
  const p8 = Deno.env.get("APNS_PRIVATE_KEY");
  if (!teamId || !keyId || !p8) return null;
  if (apnsJwt && Date.now() - apnsJwt.at < 30 * 60 * 1000) return apnsJwt.token;
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(new TextEncoder().encode(JSON.stringify({ alg: "ES256", kid: keyId })));
  const payload = b64url(new TextEncoder().encode(JSON.stringify({ iss: teamId, iat: now })));
  const input = `${header}.${payload}`;
  const key = await crypto.subtle.importKey("pkcs8", pemToDer(p8), { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(input));
  apnsJwt = { token: `${input}.${b64url(new Uint8Array(sig))}`, at: Date.now() };
  return apnsJwt.token;
}

// App Store·TestFlight 빌드는 production, Xcode 직접 설치는 sandbox. production 먼저 보내고 BadDeviceToken 이면 sandbox 로 다시 보낸다.
const APNS_HOSTS = ["https://api.push.apple.com", "https://api.sandbox.push.apple.com"];

// kind·booking_id 는 알림 data 로 앱에 전달된다 → 누르면 index.html 이 해당 화면을 연다.
async function sendApns(jwt: string, token: string, title: string, body: string, kind: string, bookingId: string | null) {
  const payload = JSON.stringify({ aps: { alert: { title, body }, sound: "default" }, kind, booking_id: bookingId });
  let lastError = "";
  for (const host of APNS_HOSTS) {
    const res = await fetch(`${host}/3/device/${token}`, {
      method: "POST",
      headers: { authorization: `bearer ${jwt}`, "apns-topic": TOPIC, "apns-push-type": "alert", "apns-priority": "10", "content-type": "application/json" },
      body: payload,
    });
    if (res.ok) return { ok: true, gone: false, error: "" };
    const txt = await res.text();
    // 앱을 지운 기기는 410 Unregistered → 토큰을 지운다
    if (res.status === 410 || txt.includes("Unregistered")) return { ok: false, gone: true, error: `${res.status} ${txt}` };
    // 토큰 환경이 반대이거나, 키가 한쪽 환경 전용이면 다른 호스트로 다시 보낸다.
    if (txt.includes("BadDeviceToken") || txt.includes("BadEnvironmentKeyInToken")) {
      lastError += `${host} ${res.status} ${txt} `;
      continue;
    }
    return { ok: false, gone: false, error: `${res.status} ${txt}` };
  }
  // 두 호스트 모두 BadDeviceToken 이면 죽은 토큰, 키 환경 문제면 토큰은 남기고 오류를 알린다.
  if (lastError.includes("BadEnvironmentKeyInToken")) return { ok: false, gone: false, error: lastError };
  return { ok: false, gone: true, error: lastError };
}

// 예약 알림 제목은 기기 언어로 쓴다. 중국어·일본어 화면은 영어로 보낸다. 공지는 관리자가 쓴 문장 그대로.
const TITLE: Record<string, Record<string, string>> = {
  booking_new: { vi: "Có lịch đặt mới", ko: "새 예약이 들어왔습니다", en: "New booking received" },
  booking_confirmed: { vi: "Đã xác nhận đặt lịch", ko: "예약이 확정되었습니다", en: "Your booking is confirmed" },
  booking_on_the_way: { vi: "Kỹ thuật viên đang trên đường đến", ko: "테라피스트가 출발했습니다", en: "Your therapist is on the way" },
  booking_completed: { vi: "Dịch vụ đã hoàn tất. Hãy để lại đánh giá nhé.", ko: "서비스가 완료되었습니다. 평가를 남겨주세요", en: "Your service is complete. Please leave a review." },
  booking_cancelled: { vi: "Đã hủy đặt lịch.", ko: "예약이 취소되었습니다.", en: "Your booking has been cancelled." },
};

type Noti = { id: string; user_id: string; title: string | null; body: string | null; kind: string; booking_id: string | null };
type Tok = { token: string; user_id: string; lang: string };

Deno.serve(async (req) => {
  if (!NOTIFY_SECRET || req.headers.get("x-notify-secret") !== NOTIFY_SECRET) return json({ error: "unauthorized" }, 401);
  // 키가 없으면 알림을 "보냄"으로 표시하기 전에 멈춘다(알림이 사라지지 않게).
  const jwt = await getApnsJwt();
  if (!jwt) return json({ error: "APNs 키(APPLE_TEAM_ID·APNS_KEY_ID·APNS_PRIVATE_KEY)가 없습니다" }, 500);

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: notis, error } = await db.rpc("claim_unpushed_notifications").returns<Noti[]>();
  if (error) return json({ error: error.message }, 500);
  if (!notis.length) return json({ ok: true, claimed: 0 });

  const users = [...new Set(notis.map((n) => n.user_id))];
  const { data: toks, error: e2 } = await db.from("push_tokens").select("token, user_id, lang").in("user_id", users).returns<Tok[]>();
  if (e2) return json({ error: e2.message }, 500);

  let sent = 0, removed = 0;
  const errors: string[] = [];
  for (const n of notis) {
    for (const t of toks.filter((x) => x.user_id === n.user_id)) {
      const lang = ["vi", "ko"].includes(t.lang) ? t.lang : "en";
      const title = TITLE[n.kind]?.[lang] ?? n.title ?? "massa";
      const r = await sendApns(jwt, t.token, title, n.body ?? "", n.kind, n.booking_id);
      if (r.ok) sent++;
      else if (r.gone) { removed++; await db.from("push_tokens").delete().eq("token", t.token); }
      if (r.error) errors.push(r.error.slice(0, 300));
    }
  }
  return json({ ok: true, claimed: notis.length, sent, removed, errors: errors.slice(0, 3) });
});
