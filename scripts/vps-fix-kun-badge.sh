#!/bin/sh
# 마지막 남은 인증 마크 한 개도 내린다.
#
# 왜: 어제는 'provider_kyc 레코드가 있으면 서류가 있다' 고 보고 Kun 만 남겼다. 그게 틀렸다.
# Kun 의 KYC 행은 비어 있다 — 신분증도, 자격증도, 사업자등록도, 정산계좌도 파일이 하나도 없다.
# 즉 지금 앱에 떠 있는 유일한 인증 마크가 근거 없는 마크다.
# 정작 신분증을 낸 Thanh hà 는 pending 상태라 노출도 안 된다.
#
# 기준을 바꾼다 — 레코드 유무가 아니라 '신분증 파일이 실제로 있는가' 로 본다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "$1"; }

echo '=== 내리기 전 ==='
SQL "select display_name, is_verified from providers where is_verified;"

SQL "
update providers p
set is_verified = false
where p.is_verified
  and not exists (
    select 1 from provider_kyc k
    where k.provider_id = p.id
      and (k.id_front_url is not null or k.id_back_url is not null)
  );
"

echo '=== 내린 뒤 (0 이어야 한다) ==='
SQL "select count(*) as 인증마크남음 from providers where is_verified;"
