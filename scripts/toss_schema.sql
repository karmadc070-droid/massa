-- 토스 결제 연동용 스키마. 여러 번 실행해도 결과가 같다
BEGIN;

-- 1) 결제수단에 toss(선불 카드) 추가
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'payment_method' AND e.enumlabel = 'toss'
  ) THEN
    ALTER TYPE payment_method ADD VALUE 'toss';
  END IF;
END $$;

COMMIT;

BEGIN;

-- 2) 결제 거래 기록
--    status      pending | paid | failed | cancelled
--    amount      실제 청구 금액(원) / amount_vnd 는 표시용 원가(동)
--    payment_key 토스 승인 후 받는 키, method 는 카드·간편결제 등
--    test_mode   토스 키가 없을 때의 모의 승인 여부
-- 주의: 컬럼 정의 줄 끝에 한글 주석을 붙이면 SSH 로 넘길 때 인코딩이 깨져 컬럼이 누락된다
CREATE TABLE IF NOT EXISTS public.payment_transactions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     text UNIQUE NOT NULL,
  booking_id   uuid REFERENCES public.bookings(id) ON DELETE SET NULL,
  customer_id  uuid NOT NULL,
  amount       integer NOT NULL,
  amount_vnd   integer,
  order_name   text,
  status       text NOT NULL DEFAULT 'pending',
  payment_key  text,
  method       text,
  receipt_url  text,
  test_mode    boolean NOT NULL DEFAULT true,
  fail_reason  text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  paid_at      timestamptz,
  cancelled_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_paytx_booking  ON public.payment_transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_paytx_customer ON public.payment_transactions(customer_id, created_at DESC);

-- 3) 예약에 결제 추적 컬럼
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS paid_at    timestamptz;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS paid_krw   integer;
ALTER TABLE public.bookings ADD COLUMN IF NOT EXISTS payment_tx uuid REFERENCES public.payment_transactions(id) ON DELETE SET NULL;

-- 4) RLS — 본인 결제만 읽는다. 쓰기는 서버(Edge Function, service_role)만 한다
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS paytx_select_own ON public.payment_transactions;
CREATE POLICY paytx_select_own ON public.payment_transactions
  FOR SELECT USING (customer_id = auth.uid());

-- 관리자는 전부 본다
DROP POLICY IF EXISTS paytx_select_admin ON public.payment_transactions;
CREATE POLICY paytx_select_admin ON public.payment_transactions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

COMMIT;

-- 확인
SELECT 'payment_method 값: ' || string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder)
  FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid WHERE t.typname = 'payment_method';
SELECT 'payment_transactions 컬럼 ' || count(*)::text || '개'
  FROM information_schema.columns WHERE table_name = 'payment_transactions';
SELECT 'bookings 추가 컬럼: ' || string_agg(column_name, ', ')
  FROM information_schema.columns
 WHERE table_name = 'bookings' AND column_name IN ('paid_at','paid_krw','payment_tx');
