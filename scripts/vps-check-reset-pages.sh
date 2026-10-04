#!/bin/sh
# 비밀번호 재설정 페이지가 어느 주소에 실제로 있는지 확인한다.
# RESET_REDIRECT 를 404 나는 주소로 바꾸면 재설정 메일이 통째로 죽는다.
for U in \
  https://admin.massaviet.com/reset.html \
  https://app.massaviet.com/reset.html \
  https://massa.moahagwon.com/reset.html \
  https://massaviet.com/reset.html ; do
  printf '%-42s %s\n' "$U" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$U")"
done
