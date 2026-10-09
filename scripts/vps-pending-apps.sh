#!/bin/bash
# 심사 대기 중인 테라피스트 신청을 본다. 읽기만 한다.
set -e
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select p.display_name 이름,
       to_char(p.created_at,'MM-DD HH24:MI') 신청,
       coalesce(p.service_area,'(없음)') 구역,
       coalesce(p.phone,'(없음)') 연락처,
       (p.profile_id is not null) 계정,
       (k.id_front_url is not null) 신분증앞,
       (k.id_back_url  is not null) 신분증뒤,
       (k.cert_url     is not null) 자격증,
       (k.bank_name    is not null) 계좌,
       coalesce(array_length(p.photo_urls,1),0) 사진수
  from providers p
  left join provider_kyc k on k.provider_id = p.id
 where p.application_status = 'pending'
 order by p.created_at;"
