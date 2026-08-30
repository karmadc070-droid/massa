// 토스페이먼츠 결제 — 주문 생성(create) / 승인(confirm) / 취소(cancel)
// 시크릿 키는 이 함수 안에서만 쓴다. 앱에는 절대 내려보내지 않는다.
// TOSS_SECRET_KEY 가 없으면 테스트 모드로 돌아 토스 API 를 부르지 않고 승인된 것처럼 기록한다.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TOSS_API = "https://api.tosspayments.com/v1/payments";
const VND_TO_KRW = 0.054;                 // 앱 표시와 같은 환산율
const CLIENT_KEY = Deno.env.get("TOSS_CLIENT_KEY") || "";
const SECRET_KEY = Deno.env.get("TOSS_SECRET_KEY") || "";
const TEST_MODE = !SECRET_KEY;            // 키가 없으면 모의 승인

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });

function tossAuth() {
  return "Basic " + btoa(SECRET_KEY + ":");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SUPABASE_SERVICE_KEY")!,
    );

    // 호출자 확인 — 로그인한 사용자만 쓴다
    const authz = req.headers.get("Authorization") || "";
    const jwt = authz.replace(/^Bearer\s+/i, "");
    const { data: userData } = await admin.auth.getUser(jwt);
    const user = userData?.user;
    if (!user) return json({ error: "로그인이 필요합니다." }, 401);

    const body = await req.json().catch(() => ({}));
    const action = body.action;

    // ── 주문 생성 ──────────────────────────────────────────────
    // 금액은 클라이언트를 믿지 않고 서버가 bookings 에서 읽어 계산한다
    if (action === "create") {
      const bookingId = body.booking_id;
      if (!bookingId) return json({ error: "booking_id 가 필요합니다." }, 400);

      const { data: bk, error: be } = await admin
        .from("bookings")
        .select("id, customer_id, amount_vnd, discount_vnd, is_paid, status, service_id, services(name)")
        .eq("id", bookingId)
        .single();
      if (be || !bk) return json({ error: "예약을 찾을 수 없습니다." }, 404);
      if (bk.customer_id !== user.id) return json({ error: "본인 예약만 결제할 수 있습니다." }, 403);
      if (bk.is_paid) return json({ error: "이미 결제된 예약입니다." }, 409);
      if (bk.status === "cancelled") return json({ error: "취소된 예약입니다." }, 409);

      const vnd = Math.max(0, (bk.amount_vnd || 0) - (bk.discount_vnd || 0));
      const krw = Math.round(vnd * VND_TO_KRW);
      if (krw < 100) return json({ error: "결제 금액이 너무 작습니다." }, 400);

      const orderId = "massa_" + crypto.randomUUID().replace(/-/g, "").slice(0, 24);
      const orderName = (bk as any).services?.name || "massa 예약";

      const { error: ie } = await admin.from("payment_transactions").insert({
        order_id: orderId,
        booking_id: bk.id,
        customer_id: user.id,
        amount: krw,
        amount_vnd: vnd,
        order_name: orderName,
        status: "pending",
        test_mode: TEST_MODE,
      });
      if (ie) return json({ error: "주문 생성 실패: " + ie.message }, 500);

      return json({ orderId, orderName, amount: krw, amountVnd: vnd, clientKey: CLIENT_KEY, testMode: TEST_MODE });
    }

    // ── 승인 ──────────────────────────────────────────────────
    // 토스가 돌려준 금액과 우리가 기록해 둔 금액이 같을 때만 확정한다
    if (action === "confirm") {
      const { orderId, paymentKey, amount } = body;
      if (!orderId) return json({ error: "orderId 가 필요합니다." }, 400);

      const { data: tx, error: te } = await admin
        .from("payment_transactions").select("*").eq("order_id", orderId).single();
      if (te || !tx) return json({ error: "주문을 찾을 수 없습니다." }, 404);
      if (tx.customer_id !== user.id) return json({ error: "본인 주문이 아닙니다." }, 403);
      if (tx.status === "paid") return json({ ok: true, already: true, tx });

      if (Number(amount) !== Number(tx.amount)) {
        await admin.from("payment_transactions")
          .update({ status: "failed", fail_reason: "금액 불일치" }).eq("order_id", orderId);
        return json({ error: "결제 금액이 주문과 다릅니다." }, 400);
      }

      let method = "테스트", receipt: string | null = null, key = paymentKey || ("test_" + orderId);

      if (!TEST_MODE) {
        if (!paymentKey) return json({ error: "paymentKey 가 필요합니다." }, 400);
        const r = await fetch(`${TOSS_API}/confirm`, {
          method: "POST",
          headers: { Authorization: tossAuth(), "Content-Type": "application/json" },
          body: JSON.stringify({ paymentKey, orderId, amount: tx.amount }),
        });
        const t = await r.json();
        if (!r.ok) {
          await admin.from("payment_transactions")
            .update({ status: "failed", fail_reason: t?.message || ("HTTP " + r.status) }).eq("order_id", orderId);
          return json({ error: t?.message || "토스 승인 실패", code: t?.code }, 400);
        }
        method = t.method || "카드";
        receipt = t.receipt?.url || null;
        key = t.paymentKey;
      }

      const now = new Date().toISOString();
      // 갱신 실패를 삼키면 "승인됐는데 기록은 pending" 인 상태가 생긴다. 반드시 확인한다
      const { error: ue } = await admin.from("payment_transactions").update({
        status: "paid", payment_key: key, method, receipt_url: receipt, paid_at: now,
      }).eq("order_id", orderId);
      if (ue) return json({ error: "결제 기록 갱신 실패: " + ue.message }, 500);

      if (tx.booking_id) {
        const { error: be2 } = await admin.from("bookings").update({
          is_paid: true, paid_at: now, paid_krw: tx.amount,
          payment_tx: tx.id, payment_method: "toss",
        }).eq("id", tx.booking_id);
        if (be2) return json({ error: "예약 갱신 실패: " + be2.message }, 500);
      }

      return json({ ok: true, testMode: TEST_MODE, orderId, amount: tx.amount, method, receiptUrl: receipt });
    }

    // ── 취소(환불) ────────────────────────────────────────────
    if (action === "cancel") {
      const { orderId, reason } = body;
      if (!orderId) return json({ error: "orderId 가 필요합니다." }, 400);

      const { data: tx } = await admin
        .from("payment_transactions").select("*").eq("order_id", orderId).single();
      if (!tx) return json({ error: "주문을 찾을 수 없습니다." }, 404);
      if (tx.customer_id !== user.id) return json({ error: "본인 주문이 아닙니다." }, 403);
      if (tx.status !== "paid") return json({ error: "결제 완료된 주문만 취소할 수 있습니다." }, 409);

      if (!TEST_MODE && tx.payment_key) {
        const r = await fetch(`${TOSS_API}/${tx.payment_key}/cancel`, {
          method: "POST",
          headers: { Authorization: tossAuth(), "Content-Type": "application/json" },
          body: JSON.stringify({ cancelReason: reason || "고객 취소" }),
        });
        const t = await r.json();
        if (!r.ok) return json({ error: t?.message || "토스 취소 실패" }, 400);
      }

      const now = new Date().toISOString();
      await admin.from("payment_transactions")
        .update({ status: "cancelled", cancelled_at: now, fail_reason: reason || null }).eq("order_id", orderId);
      if (tx.booking_id) {
        await admin.from("bookings").update({ is_paid: false, paid_at: null }).eq("id", tx.booking_id);
      }
      return json({ ok: true, testMode: TEST_MODE });
    }

    return json({ error: "알 수 없는 action 입니다." }, 400);
  } catch (e) {
    return json({ error: String(e?.message || e) }, 500);
  }
});
