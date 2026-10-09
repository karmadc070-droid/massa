#!/bin/bash
# 가입자 구분(고객/마사지사/업체)이 제대로 갈리는지 본다. 롤백한다.
A=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
    -c "select id from profiles where role='admin' limit 1;")
docker exec -i massa-db psql -U postgres -d postgres <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub','$A','role','authenticated')::text, true);

select member_type 구분, count(*) 명수 from admin_member_list() group by 1 order by 2 desc;

select full_name 이름, member_type 구분,
       coalesce(provider_status,'-') 상태, bookings 예약
  from admin_member_list()
 where member_type <> '고객';
rollback;
SQL
