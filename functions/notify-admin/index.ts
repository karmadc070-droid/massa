// 관리자에게 운영 알림 메일을 보내는 함수. DB 트리거(pg_net)와 크론이 호출한다.
// 공개 엔드포인트라 공유 시크릿으로 막는다 — 없으면 누구나 메일을 쏠 수 있는 중계기가 된다.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-notify-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

const RESEND_KEY = Deno.env.get("RESEND_KEY") ?? "";
const NOTIFY_SECRET = Deno.env.get("NOTIFY_SECRET") ?? "";
// 받는 사람. 쉼표로 여러 개. Resend 는 검증된 도메인에서만 보낼 수 있어 발신은 moahagwon.com 이다.
const TO = (Deno.env.get("ADMIN_EMAILS") ?? "").split(",").map((s) => s.trim()).filter(Boolean);
const FROM = Deno.env.get("NOTIFY_FROM") ?? "massa <massa@moahagwon.com>";
const CONSOLE_URL = "https://admin.moahagwon.com/?screen=adminSettlement";

const won = (n: number | string) => Number(n || 0).toLocaleString("en-US");
const esc = (s: unknown) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));

function shell(title: string, rows: string[][], cta = true) {
  const tr = rows
    .map(([k, v]) => `<tr><td style="padding:9px 0;color:#7A8C94;width:34%">${esc(k)}</td>
      <td style="padding:9px 0;color:#1B2B31"><b>${v}</b></td></tr>`)
    .join("");
  return `<div style="font-family:-apple-system,'Malgun Gothic',sans-serif;background:#FAF6F0;padding:26px">
  <div style="max-width:520px;margin:0 auto;background:#fff;border:1px solid #E2D8CB;border-radius:12px;padding:26px">
    <div style="font-size:13px;letter-spacing:.16em;color:#B0742F;text-transform:uppercase">massa</div>
    <h2 style="margin:8px 0 18px;font-size:21px;color:#1B2B31">${esc(title)}</h2>
    <table style="width:100%;border-collapse:collapse;font-size:14.5px">${tr}</table>
    ${cta ? `<a href="${CONSOLE_URL}" style="display:inline-block;margin-top:20px;background:#1B2B31;color:#FAF6F0;
      text-decoration:none;padding:12px 22px;border-radius:999px;font-size:14px">관리자 콘솔에서 확인</a>` : ""}
    <p style="margin:20px 0 0;font-size:12px;color:#9A8E85">이 메일은 massa 운영 시스템이 자동으로 보냅니다.</p>
  </div></div>`;
}

async function send(subject: string, html: string) {
  if (!RESEND_KEY) return { ok: false, why: "RESEND_KEY 미설정" };
  if (!TO.length) return { ok: false, why: "ADMIN_EMAILS 미설정" };
  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${RESEND_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: FROM, to: TO, subject, html }),
  });
  const t = await r.text();
  return { ok: r.ok, status: r.status, body: t.slice(0, 300) };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (NOTIFY_SECRET && req.headers.get("x-notify-secret") !== NOTIFY_SECRET) {
    return json({ error: "unauthorized" }, 401);
  }

  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch { /* 빈 본문도 허용 */ }
  const action = String(body.action ?? "deposit_reported");

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SUPABASE_SERVICE_KEY")!,
  );

  // ── 입금 신고가 들어왔다 ─────────────────────────────
  if (action === "deposit_reported") {
    const id = String(body.deposit_id ?? "");
    if (!id) return json({ error: "deposit_id 없음" }, 400);
    const { data: d } = await admin.from("provider_deposit")
      .select("id, kind, amount_vnd, bonus_vnd, memo, reported_at, provider_id").eq("id", id).single();
    if (!d) return json({ error: "입금 내역 없음" }, 404);
    const { data: p } = await admin.from("providers")
      .select("display_name, deposit_code").eq("id", d.provider_id).single();

    const isPrepay = d.kind === "prepay";
    const rows: string[][] = [
      ["마사지사", esc(p?.display_name ?? "(이름 없음)")],
      ["입금 코드", `<span style="font-family:monospace">${esc(p?.deposit_code ?? "-")}</span>`],
      ["종류", isPrepay ? "선입금(페이백)" : "수수료"],
      ["신고 금액", `${won(d.amount_vnd)}₫`],
    ];
    if (isPrepay && Number(d.bonus_vnd) > 0) rows.push(["보너스 적립", `${won(d.bonus_vnd)}₫`]);
    if (d.memo) rows.push(["이체 메모", esc(d.memo)]);
    rows.push(["신고 시각", new Date(d.reported_at as string).toLocaleString("ko-KR", { timeZone: "Asia/Seoul" })]);

    const subject = `[massa] ${p?.deposit_code ?? ""} ${isPrepay ? "선입금" : "수수료"} 입금 신고 · ${won(d.amount_vnd)}₫`;
    const html = shell("입금 신고가 접수되었습니다", rows) +
      `<div style="max-width:520px;margin:0 auto;font-family:-apple-system,'Malgun Gothic',sans-serif;
        font-size:13px;color:#7A8C94;padding:0 26px 26px">통장에서 위 코드와 금액을 확인한 뒤 콘솔에서 승인해 주세요.</div>`;
    const r = await send(subject, html);
    return json({ ok: r.ok, sent_to: TO, detail: r });
  }

  // ── 하루 한 번 미처리 현황 ───────────────────────────
  if (action === "daily_digest") {
    const { data: pend } = await admin.from("provider_deposit")
      .select("amount_vnd, kind, memo, reported_at, providers(display_name, deposit_code)")
      .eq("status", "reported").order("reported_at");
    const { data: due } = await admin.from("settlement_cycle")
      .select("fee_vnd, due_date, providers(display_name, deposit_code)")
      .neq("status", "paid").lt("due_date", new Date().toISOString().slice(0, 10));

    if (!(pend?.length || due?.length)) return json({ ok: true, skipped: "처리할 건이 없어 보내지 않음" });

    const list = (arr: unknown[] | null, f: (x: any) => string) =>
      (arr ?? []).map((x) => `<li style="margin:6px 0">${f(x)}</li>`).join("") || "<li style='color:#9A8E85'>없음</li>";
    const html = `<div style="font-family:-apple-system,'Malgun Gothic',sans-serif;background:#FAF6F0;padding:26px">
      <div style="max-width:560px;margin:0 auto;background:#fff;border:1px solid #E2D8CB;border-radius:12px;padding:26px">
        <div style="font-size:13px;letter-spacing:.16em;color:#B0742F">MASSA</div>
        <h2 style="margin:8px 0 4px;font-size:21px">오늘 처리할 정산</h2>
        <h3 style="font-size:15px;margin:20px 0 6px">확인 대기 중인 입금 신고 (${pend?.length ?? 0}건)</h3>
        <ul style="margin:0;padding-left:18px;font-size:14px">${list(pend, (x) =>
          `<b>${esc(x.providers?.deposit_code ?? "")}</b> ${esc(x.providers?.display_name ?? "")} · ${won(x.amount_vnd)}₫${x.memo ? ` · 메모 ${esc(x.memo)}` : ""}`)}</ul>
        <h3 style="font-size:15px;margin:22px 0 6px">입금 기한이 지난 건 (${due?.length ?? 0}건)</h3>
        <ul style="margin:0;padding-left:18px;font-size:14px">${list(due, (x) =>
          `<b>${esc(x.providers?.deposit_code ?? "")}</b> ${esc(x.providers?.display_name ?? "")} · ${won(x.fee_vnd)}₫ · 기한 ${esc(x.due_date)}`)}</ul>
        <a href="${CONSOLE_URL}" style="display:inline-block;margin-top:22px;background:#1B2B31;color:#FAF6F0;
          text-decoration:none;padding:12px 22px;border-radius:999px;font-size:14px">관리자 콘솔 열기</a>
      </div></div>`;
    const r = await send(`[massa] 정산 현황 · 대기 ${pend?.length ?? 0}건 · 지연 ${due?.length ?? 0}건`, html);
    return json({ ok: r.ok, sent_to: TO, detail: r });
  }

  // ── 설정 점검용 ──────────────────────────────────────
  if (action === "test") {
    const r = await send("[massa] 알림 메일 설정 확인", shell("알림 메일이 정상 동작합니다", [
      ["받는 사람", TO.join(", ")], ["보낸 사람", esc(FROM)],
      ["확인 시각", new Date().toLocaleString("ko-KR", { timeZone: "Asia/Seoul" })],
    ], false));
    return json({ ok: r.ok, sent_to: TO, detail: r });
  }

  return json({ error: "알 수 없는 action: " + action }, 400);
});
