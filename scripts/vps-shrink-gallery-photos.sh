#!/bin/bash
# 프로필 상세의 갤러리 사진(photo_urls)을 줄인다. 목록 아바타는 이미 끝냈고(Z-25) 이게 남았다.
#
# 아바타는 400px 로 줬지만 갤러리는 손님이 크게 보는 사진이라 900px 로 둔다.
# 원본은 photo_urls_orig 에 통째로 남겨 되돌릴 수 있게 한다.
#
# 함정 두 개는 이미 겪었다 (Z-25).
#   · docker exec -i 가 while 루프의 stdin 을 삼킨다 → SQL 은 </dev/null, 루프는 fd 3
#   · raw.githubusercontent 는 캐시된다 → 이 스크립트는 커밋 SHA 로 받아서 실행할 것
set -e

ENVF=/root/massa/.env
KEY=$(grep -E '^SERVICE_ROLE_KEY=' "$ENVF" | cut -d= -f2-)
API=https://api.moahagwon.com
BUCKET=provider-photos
SQL() { docker exec -i massa-db psql -U postgres -d postgres "$@" < /dev/null; }

echo '=== 0. 준비 ==='
python3 -c 'import PIL' 2>/dev/null || pip3 install --quiet --break-system-packages Pillow
SQL -c "alter table providers add column if not exists photo_urls_orig text[];"
SQL -c "update providers set photo_urls_orig = photo_urls
        where photo_urls_orig is null and coalesce(array_length(photo_urls,1),0) > 0;"

echo ''
echo '=== 1. 대상 목록 (provider_id | 배열 위치 | 원본 주소) ==='
SQL -tAc "
select p.id || '|' || u.ord || '|' || u.url
from providers p,
     lateral unnest(coalesce(p.photo_urls_orig, p.photo_urls)) with ordinality as u(url, ord)
where p.is_active and p.application_status = 'approved'
  and u.url like 'http%';" > /tmp/glist.txt
echo "  $(wc -l < /tmp/glist.txt) 장"

mkdir -p /tmp/gal && rm -f /tmp/gal/*
BEFORE=0; AFTER=0; N=0; FAIL=0

while IFS='|' read -r PID ORD URL <&3; do
  [ -z "$PID" ] && continue
  N=$((N+1))
  SRC=/tmp/gal/src_$N
  if ! curl -s --max-time 60 -o "$SRC" "$URL"; then echo "  [$N] 내려받기 실패"; FAIL=$((FAIL+1)); continue; fi
  B=$(wc -c < "$SRC"); BEFORE=$((BEFORE+B))

  OUT=/tmp/gal/${PID}_$ORD.webp
  if ! python3 - "$SRC" "$OUT" <<'PY'
import sys
from PIL import Image, ImageOps
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src)
im = ImageOps.exif_transpose(im)
if im.mode in ("RGBA", "LA", "P"):
    im = im.convert("RGBA")
    bg = Image.new("RGB", im.size, (255, 255, 255))
    bg.paste(im, mask=im.split()[-1] if im.mode == "RGBA" else None)
    im = bg
else:
    im = im.convert("RGB")
# 갤러리는 크게 보는 사진이라 아바타(400)보다 넉넉하게 둔다
im.thumbnail((900, 900), Image.LANCZOS)
im.save(out, "WEBP", quality=80, method=6)
PY
  then echo "  [$N] 변환 실패"; FAIL=$((FAIL+1)); continue; fi

  A=$(wc -c < "$OUT"); AFTER=$((AFTER+A))
  STAMP=$(date +%s)
  curl -s -X POST "$API/storage/v1/object/$BUCKET/gallery/${PID}_$ORD.webp" \
    -H "Authorization: Bearer $KEY" -H "apikey: $KEY" \
    -H "Content-Type: image/webp" -H "Cache-Control: max-age=31536000" \
    -H "x-upsert: true" --data-binary "@$OUT" -o /tmp/gup.json
  if ! grep -q '"Key"' /tmp/gup.json; then
    echo "  [$N] 업로드 실패: $(head -c 120 /tmp/gup.json)"; FAIL=$((FAIL+1)); continue
  fi

  NEW="$API/storage/v1/object/public/$BUCKET/gallery/${PID}_$ORD.webp?v=$STAMP"
  # 배열의 그 자리만 바꾼다. 순서가 유지돼야 프로필에서 보던 차례가 안 흐트러진다.
  SQL -c "update providers set photo_urls[$ORD] = '$NEW' where id = '$PID';" > /dev/null
  printf '  [%2d] %7d KB -> %4d KB\n' "$N" $((B/1024)) $((A/1024))
done 3< /tmp/glist.txt

echo ''
echo "=== 2. 합계 ==="
printf '  전: %d MB\n  후: %d KB\n  실패: %d 건\n' $((BEFORE/1048576)) $((AFTER/1024)) "$FAIL"

echo ''
echo '=== 3. 확인 — 남은 원본 크기 주소가 있나 (0 이어야 한다) ==='
SQL -c "
select count(*) as still_original
from providers p, lateral unnest(coalesce(p.photo_urls,'{}')) as u(url)
where p.is_active and p.application_status='approved'
  and u.url like 'http%' and u.url not like '%/gallery/%';"

echo ''
echo '=== 4. 표본 세 장이 실제로 열리는가 ==='
SQL -tAc "
select u.url from providers p, lateral unnest(coalesce(p.photo_urls,'{}')) as u(url)
where p.is_active and p.application_status='approved' and u.url like '%gallery%' limit 3;" \
| while read -r u; do
    [ -n "$u" ] && printf '  code=%s bytes=%s type=%s\n' \
      "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")" \
      "$(curl -s -o /dev/null -w '%{size_download}' --max-time 20 "$u")" \
      "$(curl -s -o /dev/null -w '%{content_type}' --max-time 20 "$u")"
  done
