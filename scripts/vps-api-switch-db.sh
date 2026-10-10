#!/bin/bash
# DB 에 박혀 있는 사진 주소를 api.moahagwon.com → api.massaviet.com 으로 바꾼다.
#
# 사전 점검(vps-api-switch-precheck.sh)에서 같은 사진이 두 주소 모두 200 으로 열리는 것을
# 확인했다. 그래서 바꿔도 사진이 깨지지 않는다.
#
# 옛 주소를 지우지는 않는다. 업데이트 안 한 앱이 아직 그 주소를 부른다.
set -e

TS=$(date +%Y%m%d-%H%M%S)
DIR=/root/massa-backup/api-switch-$TS
mkdir -p "$DIR"

echo "=== 1. 백업 ($DIR) ==="
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /dev/null \
  -c "copy (select id, display_name, photo_url, photo_urls, video_url from providers) to stdout with csv header" \
  > "$DIR/providers-photos.csv"
echo "  providers-photos.csv  $(($(wc -l < "$DIR/providers-photos.csv") - 1)) 줄"

echo ''
echo '=== 2. 바꾸기 (한 트랜잭션, 행수 가드) ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<'SQL'
begin;

do $$
declare n1 int; n2 int;
begin
  select count(*) into n1 from providers where photo_url like '%api.moahagwon.com%';
  select count(*) into n2 from providers where array_to_string(photo_urls, ',') like '%api.moahagwon.com%';
  raise notice 'photo_url % 행 / photo_urls % 행', n1, n2;
  -- 사전 점검에서 센 값과 다르면 그 사이에 뭔가 바뀐 것이다. 멈추고 사람이 본다.
  if n1 + n2 > 20 then
    raise exception '예상(7행)보다 너무 많다 (%행) - 중단한다', n1 + n2;
  end if;
end $$;

update providers
   set photo_url = replace(photo_url, 'api.moahagwon.com', 'api.massaviet.com')
 where photo_url like '%api.moahagwon.com%';

-- 배열은 원소마다 바꾼다. 통째로 문자열 치환하면 배열이 깨진다.
update providers
   set photo_urls = (select array_agg(replace(u, 'api.moahagwon.com', 'api.massaviet.com')
                                      order by ord)
                       from unnest(photo_urls) with ordinality as t(u, ord))
 where array_to_string(photo_urls, ',') like '%api.moahagwon.com%';

commit;
SQL

echo ''
echo '=== 3. 남은 옛 주소 (0 이어야 한다) ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) filter (where photo_url like '%api.moahagwon.com%') photo_url,
       count(*) filter (where array_to_string(photo_urls,',') like '%api.moahagwon.com%') photo_urls
  from providers;"

echo '=== 4. 바뀐 사진이 실제로 열리나 ==='
docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
  -c "select photo_url from providers where photo_url like 'http%' limit 3" \
| while read -r u; do
    printf '  %s  %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")" "$(echo "$u" | head -c 85)"
  done

echo ''
echo "=== 되돌리려면 ==="
echo "  $DIR/providers-photos.csv 의 값을 다시 넣으면 된다"
