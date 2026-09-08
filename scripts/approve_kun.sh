#!/bin/sh
# Kun 한 명만 승인한다. 앱의 reviewApp() 과 똑같은 칸을 채우고 알림도 같이 남긴다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\set ON_ERROR_STOP off
select id as kun from public.providers
 where display_name = 'Kun' and application_status = 'pending' \gset
select id as adm from public.profiles where role = 'admin' limit 1 \gset

\echo '=== 승인하기 전 — 신청 내용 ==='
select p.display_name as 이름, p.kind::text as 구분,
       coalesce(u.email,'(없음)') as 계정,
       coalesce(p.base_district,'-') as 지역,
       coalesce(p.service_area,'-') as 활동범위,
       coalesce(array_length(p.photo_urls,1),0) as 사진수,
       array_to_string(p.specialties, ', ') as 전문분야,
       coalesce(p.bio,'-') as 소개
  from public.providers p
  left join auth.users u on u.id = coalesce(p.profile_id, p.owner_id)
 where p.id = :'kun';

\echo '--- 제출 서류 (있는지만 본다, 내용은 보지 않는다) ---'
select case when id_front_url        is not null then '있음' else '★ 없음' end as 신분증앞,
       case when id_back_url         is not null then '있음' else '★ 없음' end as 신분증뒤,
       case when contact             is not null then '있음' else '★ 없음' end as 연락처,
       case when bank_account        is not null then '있음' else '★ 없음' end as 계좌,
       case when cert_url            is not null then '있음' else '없음'   end as 자격증,
       case when business_license_url is not null then '있음' else '없음'  end as 사업자
  from public.provider_kyc where provider_id = :'kun';

\echo '--- 예약 가능한 코스가 붙어 있는가 ---'
select count(*) as 연결된코스 from public.provider_services where provider_id = :'kun';

\echo ''
\echo '=== 승인 처리 ==='
update public.providers
   set application_status = 'approved',
       is_verified = true,
       is_active   = true,
       reviewed_at = now(),
       reviewed_by = :'adm',
       reject_reason = null
 where id = :'kun';

-- 신청자에게 알림 (앱의 reviewApp 과 같은 문구)
insert into public.notifications (user_id, title, body, kind)
select coalesce(p.profile_id, p.owner_id), '등록 승인 안내',
       '등록 신청이 승인되었습니다. 이제 고객 목록에 노출되며 예약을 받을 수 있어요.', 'info'
  from public.providers p
 where p.id = :'kun' and coalesce(p.profile_id, p.owner_id) is not null;

\echo ''
\echo '=== 확인 ==='
select display_name as 이름, application_status::text as 상태,
       is_verified as 인증, is_active as 출근,
       to_char(reviewed_at at time zone 'Asia/Ho_Chi_Minh','MM-DD HH24:MI') as 승인시각
  from public.providers where id = :'kun';

select '남은 심사 대기 ' || count(*) || '명' as 확인
  from public.providers where application_status = 'pending';

select display_name as 남은대기, coalesce(u.email,'(없음)') as 계정
  from public.providers p left join auth.users u on u.id = coalesce(p.profile_id,p.owner_id)
 where p.application_status = 'pending' order by p.created_at;
PSQL
