#!/bin/bash
# 마사지사 목록 사진을 400px WebP 사본으로 바꾼다. 원본은 지우지 않는다.
#
# 왜: 홈 화면이 23장 / 44.8MB 를 받고 있었다. 100px 썸네일에 2.18MB PNG 를 쓰고 있었다.
# 어떻게: 원본을 받아 400px WebP 로 줄여 storage 의 thumb/ 에 올리고, photo_url 만 바꾼다.
#        원래 주소는 providers.photo_url_orig 에 남겨 언제든 되돌릴 수 있게 한다.
set -e

ENVF=/root/massa/.env
KEY=$(grep -E '^SERVICE_ROLE_KEY=' "$ENVF" | cut -d= -f2-)
API=https://api.moahagwon.com
BUCKET=provider-photos
# ★ docker exec -i 는 표준입력을 통째로 삼킨다. 목록을 while 로 돌리는 중에 부르면
# 남은 줄을 전부 먹어 버려서 루프가 첫 번째에서 끝난다 (실제로 한 번 당했다).
# 그래서 SQL 은 항상 /dev/null 에서 읽게 못 박고, 루프는 fd 3 으로 따로 읽는다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres "$@" < /dev/null; }

echo '=== 0. 도구 준비 ==='
python3 -c 'import PIL' 2>/dev/null || pip3 install --quiet --break-system-packages Pillow
python3 -c 'import PIL; print("  Pillow", PIL.__version__)'

echo ''
echo '=== 1. 되돌릴 자리 만들기 (원본 주소 보관) ==='
SQL -c "alter table providers add column if not exists photo_url_orig text;"
SQL -c "update providers set photo_url_orig = photo_url
        where photo_url_orig is null and photo_url like 'http%';"

echo ''
echo '=== 2. 원본 주소 목록 ==='
SQL -tAc "select id || '|' || coalesce(photo_url_orig, photo_url)
          from providers
          where is_active and application_status='approved'
            and coalesce(photo_url_orig, photo_url) like 'http%';" > /tmp/plist.txt
echo "  $(wc -l < /tmp/plist.txt) 명"

mkdir -p /tmp/thumbs && rm -f /tmp/thumbs/*
BEFORE=0; AFTER=0; N=0

while IFS='|' read -r PID URL <&3; do
  [ -z "$PID" ] && continue
  N=$((N+1))
  SRC=/tmp/thumbs/src_$N
  curl -s --max-time 60 -o "$SRC" "$URL" || { echo "  [$N] 내려받기 실패 — 건너뜀"; continue; }
  B=$(wc -c < "$SRC"); BEFORE=$((BEFORE+B))

  OUT=/tmp/thumbs/$PID.webp
  python3 - "$SRC" "$OUT" <<'PY' || { echo "  [$N] 변환 실패 — 건너뜀"; continue; }
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
# 목록 아바타는 한 변 400px 이면 2배 화면에서도 충분하다.
im.thumbnail((400, 400), Image.LANCZOS)
im.save(out, "WEBP", quality=82, method=6)
PY

  A=$(wc -c < "$OUT"); AFTER=$((AFTER+A))
  # 1년 캐시. 파일명이 마사지사 id 라 사진을 바꾸면 같은 이름에 덮어써진다 —
  # 그래서 바꾼 시각을 쿼리로 붙여 주소를 달라지게 한다.
  STAMP=$(date +%s)
  curl -s -X POST "$API/storage/v1/object/$BUCKET/thumb/$PID.webp" \
    -H "Authorization: Bearer $KEY" -H "apikey: $KEY" \
    -H "Content-Type: image/webp" -H "Cache-Control: max-age=31536000" \
    -H "x-upsert: true" --data-binary "@$OUT" -o /tmp/up.json
  grep -q '"Key"' /tmp/up.json || { echo "  [$N] 업로드 실패: $(head -c 120 /tmp/up.json)"; continue; }

  NEW="$API/storage/v1/object/public/$BUCKET/thumb/$PID.webp?v=$STAMP"
  SQL -c "update providers set photo_url='$NEW' where id='$PID';" > /dev/null
  printf '  [%2d] %7d KB -> %4d KB\n' "$N" $((B/1024)) $((A/1024))
done 3< /tmp/plist.txt

echo ''
echo "=== 3. 합계 ==="
printf '  전: %d MB\n  후: %d KB\n' $((BEFORE/1048576)) $((AFTER/1024))

echo ''
echo '=== 4. 확인 — 바뀐 주소가 실제로 열리고 작은가 ==='
SQL -tAc "select photo_url from providers
          where is_active and application_status='approved' limit 3;" \
| while read -r u; do
    [ -n "$u" ] && printf '  %s  code=%s bytes=%s type=%s\n' \
      "$(echo "$u" | sed 's/.*thumb\///')" \
      "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")" \
      "$(curl -s -o /dev/null -w '%{size_download}' --max-time 20 "$u")" \
      "$(curl -s -o /dev/null -w '%{content_type}' --max-time 20 "$u")"
  done

echo ''
echo '=== DONE ==='
