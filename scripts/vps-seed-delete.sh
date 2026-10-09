#!/bin/bash
# 시드 마사지사 22명을 완전히 삭제한다.
#
# 왜 지우나 - 끄고 두기만 했더니 오늘(Z-43) UPDATE 조건 하나 빠뜨려서 전부 다시 켜졌다.
#            존재하는 한 같은 사고가 또 난다. 지우면 그 실패 경로가 사라진다.
#
# 대상 - profile_id 가 없는 행. 로그인 계정이 없으니 실존 인물이 아니다.
#        사전 점검에서 예약 0 · 후기 0 을 확인했다.
#
# 안전장치 세 겹
#   1) 지우기 전에 관련 테이블을 전부 CSV 로 뜬다 (복구 가능)
#   2) 한 트랜잭션 안에서, 지울 행 수가 예상과 다르면 스스로 중단한다
#   3) 로그인 계정이 있는 행이 하나라도 섞이면 중단한다
set -e

TS=$(date +%Y%m%d-%H%M%S)
DIR=/root/massa-backup/seed-delete-$TS
mkdir -p "$DIR"

echo "=== 1. 백업 ($DIR) ==="
for q in \
  "providers:select * from providers where profile_id is null" \
  "provider_services:select s.* from provider_services s join providers p on p.id=s.provider_id where p.profile_id is null" \
  "favorites:select f.* from favorites f join providers p on p.id=f.provider_id where p.profile_id is null" \
  "provider_kyc:select k.* from provider_kyc k join providers p on p.id=k.provider_id where p.profile_id is null" \
; do
  name="${q%%:*}"; sql="${q#*:}"
  # \copy 는 psql 클라이언트 명령이라 docker exec 안에서 경로가 꼬인다. 서버쪽 copy to stdout 을 쓴다.
  docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
    -c "copy ($sql) to stdout with csv header" < /dev/null > "$DIR/$name.csv"
  printf '  %-20s %s 줄\n' "$name" "$(($(wc -l < "$DIR/$name.csv") - 1))"
done

echo ''
echo '=== 2. 삭제 (한 트랜잭션, 안전장치 포함) ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<'SQL'
begin;

do $$
declare n_total int; n_login int; n_active int; n_bk int; n_rv int;
begin
  select count(*) into n_total  from providers where profile_id is null;
  select count(*) into n_login  from providers where profile_id is null and owner_id is not null;
  select count(*) into n_active from providers where profile_id is null and is_active;
  select count(*) into n_bk from bookings b join providers p on p.id=b.provider_id where p.profile_id is null;
  select count(*) into n_rv from reviews  r join providers p on p.id=r.provider_id where p.profile_id is null;

  raise notice '대상 % 명 / 로그인있음 % / 켜져있음 % / 예약 % / 후기 %',
    n_total, n_login, n_active, n_bk, n_rv;

  if n_total <> 22 then
    raise exception '대상이 22명이 아니라 %명이다 - 중단한다. 누가 추가·삭제했는지 먼저 확인할 것', n_total;
  end if;
  if n_login > 0 then
    raise exception '로그인 계정이 달린 행이 %개 섞였다 - 중단한다', n_login;
  end if;
  if n_active > 0 then
    raise exception '아직 켜져 있는 행이 %개 있다 - 중단한다', n_active;
  end if;
  if n_bk > 0 or n_rv > 0 then
    raise exception '예약 %건 후기 %건이 달려 있다 - 중단한다', n_bk, n_rv;
  end if;
end $$;

delete from providers where profile_id is null;

commit;
SQL

echo ''
echo '=== 3. 결과 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) 남은_마사지사,
       count(*) filter (where is_active) 노출중,
       count(*) filter (where profile_id is null) 계정없는것
  from providers;"
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select display_name 이름, application_status::text 상태, is_active 노출, is_verified 인증
  from providers order by created_at;"

echo ''
echo "=== 되돌리려면 ==="
echo "  $DIR/providers.csv 를 \\copy providers from ... 로 넣으면 된다"
echo "  (딸린 provider_services, favorites, provider_kyc 도 같은 폴더에 있다)"
