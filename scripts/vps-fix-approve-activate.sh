#!/bin/bash
# 앞 스크립트가 빠뜨린 것을 메운다.
#
# 무엇이 틀렸나 - 관리자 화면의 reviewApp() 은 승인할 때 세 가지를 한다.
#   1) application_status = 'approved'
#   2) is_active = true          <- 이걸 빠뜨렸다. 그래서 승인됐는데 목록에 안 보였다
#   3) 신청자에게 알림 발송      <- 이것도 빠뜨렸다
# SQL 로 직접 상태만 바꾸는 바람에 2,3 이 누락됐다.
#
# is_verified 는 여전히 건드리지 않는다. 그건 서류를 눈으로 본 뒤에만 준다.
set -e

echo '=== 1. 대상 (오늘 승인됐는데 목록에 안 보이는 사람) ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select display_name, is_active, to_char(reviewed_at,'MM-DD HH24:MI') 승인
  from providers
 where application_status='approved' and is_active = false;"

echo ''
echo '=== 2. 목록에 노출 + 알림 발송 ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQL'
begin;

-- 알림을 먼저 만든다 (아직 is_active=false 인 사람만 골라야 하므로)
insert into notifications (user_id, title, body, kind)
select coalesce(p.profile_id, p.owner_id),
       'Đăng ký đã được duyệt',
       'Đăng ký đối tác của bạn đã được duyệt. Từ bây giờ bạn hiển thị trong danh sách và có thể nhận lịch đặt.',
       'info'
  from providers p
 where p.application_status = 'approved'
   and p.is_active = false
   and coalesce(p.profile_id, p.owner_id) is not null;

update providers
   set is_active = true
 where application_status = 'approved'
   and is_active = false;

commit;
SQL

echo ''
echo '=== 3. 결과 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select display_name, application_status, is_active, is_verified,
       coalesce(service_area,'-') 구역
  from providers
 where profile_id is not null
 order by created_at;"

echo '=== 고객 목록에 보이는 파트너 수 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) from providers where is_active and application_status='approved';"
