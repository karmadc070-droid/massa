#!/bin/sh
# providers / reviews / provider_kyc 의 실제 컬럼 이름을 본다. 추측하지 않기 위해서다.
set -e
for T in providers reviews provider_kyc bookings; do
  echo "=== $T ==="
  docker exec -i massa-db psql -U postgres -d postgres -Atc \
    "select column_name||' '||data_type from information_schema.columns where table_name='$T' order by ordinal_position;" \
    | sed 's/^/  /'
  echo ''
done
