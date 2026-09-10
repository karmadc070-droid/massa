// 구글 장소 검색을 중계한다. 손님이 호텔 이름을 치면 후보를 돌려주고, 고르면 좌표를 준다.
//
// 키를 앱에 넣지 않는다. Capacitor 앱은 HTTP 리퍼러 제한이 걸리지 않아서
// 앱 파일에 키를 두면 누구나 꺼내 쓸 수 있고, 그 요금은 사장님이 낸다.
// 키는 이 함수의 환경변수에만 있고 밖으로 나가지 않는다.
//
// 하노이 기준으로 반경을 좁혀 검색 품질을 올린다.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

const KEY = Deno.env.get("GOOGLE_MAPS_KEY") ?? "";

// 하노이 시내. 이 원 안을 우선해서 보여 준다 (다른 도시 결과가 섞이는 걸 막는다)
const HANOI = { lat: 21.0278, lng: 105.8342, radius: 30000 };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (!KEY) return json({ error: "지도 키가 설정되지 않았습니다." }, 503);

  let body: { q?: string; placeId?: string; session?: string; lang?: string };
  try { body = await req.json(); } catch { return json({ error: "잘못된 요청" }, 400); }

  const lang = ["ko", "vi", "en", "ja", "zh"].includes(body.lang ?? "") ? body.lang : "vi";
  const session = String(body.session ?? "").slice(0, 64) || undefined;

  try {
    // ── 1) 고른 장소의 좌표 가져오기 ──────────────────────────
    if (body.placeId) {
      const id = String(body.placeId).slice(0, 200);
      const r = await fetch(`https://places.googleapis.com/v1/places/${encodeURIComponent(id)}?languageCode=${lang}`
        + (session ? `&sessionToken=${encodeURIComponent(session)}` : ""), {
        headers: {
          "X-Goog-Api-Key": KEY,
          // 필요한 칸만 받는다. 칸을 늘리면 요금 등급이 올라간다.
          "X-Goog-FieldMask": "id,displayName,formattedAddress,location",
        },
      });
      const j = await r.json();
      if (!r.ok) return json({ error: j?.error?.message ?? "장소를 불러오지 못했습니다." }, 502);
      return json({
        place_id: j.id,
        name: j.displayName?.text ?? "",
        address: j.formattedAddress ?? "",
        lat: j.location?.latitude ?? null,
        lng: j.location?.longitude ?? null,
      });
    }

    // ── 2) 검색어로 후보 목록 ────────────────────────────────
    const q = String(body.q ?? "").trim().slice(0, 120);
    if (q.length < 2) return json({ items: [] });

    const r = await fetch("https://places.googleapis.com/v1/places:autocomplete", {
      method: "POST",
      headers: { "X-Goog-Api-Key": KEY, "Content-Type": "application/json" },
      body: JSON.stringify({
        input: q,
        languageCode: lang,
        regionCode: "VN",
        sessionToken: session,
        locationBias: {
          circle: { center: { latitude: HANOI.lat, longitude: HANOI.lng }, radius: HANOI.radius },
        },
      }),
    });
    const j = await r.json();
    if (!r.ok) return json({ error: j?.error?.message ?? "검색에 실패했습니다." }, 502);

    const items = (j.suggestions ?? [])
      .map((s: Record<string, any>) => s.placePrediction)
      .filter(Boolean)
      .slice(0, 8)
      .map((p: Record<string, any>) => ({
        place_id: p.placeId,
        name: p.structuredFormat?.mainText?.text ?? p.text?.text ?? "",
        address: p.structuredFormat?.secondaryText?.text ?? "",
      }));
    return json({ items });
  } catch (e) {
    return json({ error: String((e as Error).message ?? e) }, 500);
  }
});
