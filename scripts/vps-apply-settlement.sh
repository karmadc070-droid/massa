#!/bin/sh
# 수수료 입금 관리 스키마를 massa-db 에 적용하고 결과를 확인한다.
# 실행: VPS 에서 sh vps-apply-settlement.sh
set -e

TMP=$(mktemp -d)
curl -s --location codeload.github.com/karmadc070-droid/massa/tar.gz/refs/heads/main -o "$TMP/m.tgz"
tar -xzf "$TMP/m.tgz" -C "$TMP"
SQL="$TMP/massa-main/scripts/settlement_schema.sql"
test -s "$SQL" || { echo "SQL 을 못 받았다 — 중단"; exit 1; }

echo "=== 적용 ==="
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$SQL"
rm -rf "$TMP"

Q() { docker exec massa-db psql -U postgres -d postgres -A -t -c "$1"; }

echo
echo "=== 검증 ==="
printf '  deposit_code 채워진 제공자  %s / %s\n' \
  "$(Q "select count(*) from providers where deposit_code is not null;")" \
  "$(Q "select count(*) from providers;")"
printf '  코드 중복                   %s (0이어야 정상)\n' \
  "$(Q "select count(*) from (select deposit_code from providers where deposit_code is not null group by 1 having count(*)>1) x;")"
printf '  코드 형식 위반              %s (0이어야 정상)\n' \
  "$(Q "select count(*) from providers where deposit_code is not null and deposit_code !~ '^MS[0-9]{4}$';")"

echo "  새 테이블:"
for t in provider_deposit provider_credit provider_credit_tx; do
  printf '    %-22s %s\n' "$t" "$(Q "select case when to_regclass('public.$t') is null then '없음' else '있음' end;")"
done

echo "  RLS 켜짐:"
Q "select '    '||relname||' = '||relrowsecurity from pg_class where relname in ('provider_deposit','provider_credit','provider_credit_tx');"

echo "  함수:"
for f in owns_provider confirm_deposit is_admin; do
  printf '    %-18s %s\n' "$f" "$(Q "select count(*) from pg_proc where proname='$f';")"
done

echo "  선입금 구간 설정:"
Q "select '    '||value::text from app_settings where key='prepay';"

echo
echo "=== 코드 표본 5개 ==="
Q "select '  '||coalesce(display_name,'(이름없음)')||'  ->  '||deposit_code from providers order by created_at limit 5;" 2>/dev/null \
  || Q "select '  '||coalesce(display_name,'(이름없음)')||'  ->  '||deposit_code from providers limit 5;"

echo
echo "=== PostgREST 스키마 캐시 리로드 ==="
docker exec massa-db psql -U postgres -d postgres -c "notify pgrst, 'reload schema';" >/dev/null 2>&1 || true
docker restart massa-rest >/dev/null 2>&1 && echo "  massa-rest 재시작" || echo "  재시작 실패 — 수동 확인 필요"
sleep 5
echo "=== SETTLEMENT SCHEMA DONE ==="
