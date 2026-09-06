-- 마사지 종류를 앱에서 전부 고를 수 있게 만든다.
-- 지금까지 massage_type 이 아로마·스웨디시·타이 7건에만 있어 나머지 39건은 앱에서 도달할 수 없었다.
-- 이름만 다른 중복은 하나로 합치고(나머지는 내림), 없던 120분을 채운다.

-- ── 1. 종류 값 추가 ──────────────────────────────────────────
alter type public.massage_type add value if not exists 'hot_stone';
alter type public.massage_type add value if not exists 'foot';
alter type public.massage_type add value if not exists 'head';
alter type public.massage_type add value if not exists 'back';
alter type public.massage_type add value if not exists 'neck_shoulder';
alter type public.massage_type add value if not exists 'sports';
alter type public.massage_type add value if not exists 'cupping';
alter type public.massage_type add value if not exists 'no_oil';
