#!/bin/sh
# DB에 저장된 sslip.io URL을 찾아 api.moahagwon.com 으로 치환한다.
# 어느 컬럼에 들어 있는지 모르므로 text 계열 컬럼을 전부 훑어서 처리한다.
set -e

DB=$(docker ps --format '{{.Names}}' | grep massa | grep -i db | head -1)
echo "=== DB container: $DB ==="

docker exec -i "$DB" psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<'SQL'
\pset pager off
DO $mig$
DECLARE
  r record;
  n bigint;
  total bigint := 0;
  old_host text := 'massa.141-164-46-88.sslip.io';
  new_host text := 'api.moahagwon.com';
BEGIN
  -- 1) 단일 text 컬럼
  FOR r IN
    SELECT table_name AS t, column_name AS c
      FROM information_schema.columns
     WHERE table_schema = 'public'
       AND data_type IN ('text', 'character varying')
  LOOP
    EXECUTE format('SELECT count(*) FROM public.%I WHERE %I LIKE %L', r.t, r.c, '%' || old_host || '%') INTO n;
    IF n > 0 THEN
      RAISE NOTICE 'text  %.% : % 건 → 치환', r.t, r.c, n;
      EXECUTE format('UPDATE public.%I SET %I = replace(%I, %L, %L) WHERE %I LIKE %L',
                     r.t, r.c, r.c, old_host, new_host, r.c, '%' || old_host || '%');
      total := total + n;
    END IF;
  END LOOP;

  -- 2) text[] 배열 컬럼
  FOR r IN
    SELECT table_name AS t, column_name AS c
      FROM information_schema.columns
     WHERE table_schema = 'public' AND data_type = 'ARRAY'
  LOOP
    EXECUTE format('SELECT count(*) FROM public.%I WHERE array_to_string(%I, '','') LIKE %L', r.t, r.c, '%' || old_host || '%') INTO n;
    IF n > 0 THEN
      RAISE NOTICE 'array %.% : % 건 → 치환', r.t, r.c, n;
      EXECUTE format($f$UPDATE public.%I SET %I = (SELECT array_agg(replace(u, %L, %L)) FROM unnest(%I) AS u)
                        WHERE array_to_string(%I, ',') LIKE %L$f$,
                     r.t, r.c, old_host, new_host, r.c, r.c, '%' || old_host || '%');
      total := total + n;
    END IF;
  END LOOP;

  RAISE NOTICE '=== 치환 합계: % 건 ===', total;
END
$mig$;
SQL

echo "=== URL MIGRATE DONE ==="
