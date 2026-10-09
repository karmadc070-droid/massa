#!/bin/bash
# providers 쓰기를 막고 있는 가드 함수와 트리거를 본다. 읽기만 한다.
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c \
  "select prosrc from pg_proc where proname='guard_provider_write';"
echo '=== 어느 테이블에 어떻게 걸려 있나 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c \
  "select tgname, tgrelid::regclass::text tbl, pg_get_triggerdef(oid) def
     from pg_trigger where not tgisinternal and tgrelid::regclass::text like 'provider%';"
