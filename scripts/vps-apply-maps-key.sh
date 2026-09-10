#!/bin/sh
# 구글 지도 키를 Edge Function 환경변수에 넣고 places-search 를 배포한다.
#
# 사장님이 /root/maps.key 파일에 키 한 줄만 넣어 두면 이 스크립트가 읽어 간다.
# 키 값은 화면에 찍지 않는다. 길이만 보여 준다.
# 다 쓰면 /root/maps.key 는 shred 로 지운다 — 서버에 평문으로 남기지 않는다.
set -e

SRC=/root/maps.key
ENVF=/root/massa/.env                              # docker compose 가 읽는 파일
FN=/root/massa/volumes/functions/places-search     # 컨테이너의 /home/deno/functions 에 붙는다

[ -f "$SRC" ] || { echo "★ $SRC 가 없습니다. 키를 한 줄로 저장한 뒤 다시 실행하세요."; exit 1; }
KEY=$(tr -d ' \t\r\n' < "$SRC")
[ -n "$KEY" ] || { echo "★ 키가 비어 있습니다."; exit 1; }
echo "키 길이: ${#KEY} 자"
case "$KEY" in
  AIza*) : ;;
  *) echo "★ 구글 키는 보통 AIza 로 시작합니다. 값을 다시 확인해 주세요."; exit 1 ;;
esac

# ── 1) 환경변수 등록 (기존 줄이 있으면 갈아 끼운다) ──────────
[ -f "$ENVF" ] || { echo "★ $ENVF 가 없습니다."; exit 1; }
cp "$ENVF" "$ENVF.bak.$(date +%s)"
grep -v '^GOOGLE_MAPS_KEY=' "$ENVF" > "$ENVF.tmp" || true
printf 'GOOGLE_MAPS_KEY=%s\n' "$KEY" >> "$ENVF.tmp"
mv "$ENVF.tmp" "$ENVF"
chmod 600 "$ENVF"
echo "환경변수 등록됨 (값은 출력하지 않습니다)"

# ── 2) 함수 파일 배치 ────────────────────────────────────────
mkdir -p "$FN"
cp /root/places-search.ts "$FN/index.ts"
ls -la "$FN/index.ts"

# ── 3) Edge Functions 컨테이너 재시작 ────────────────────────
# 환경변수는 컨테이너를 다시 만들어야 들어간다. restart 만으로는 안 바뀐다.
cd /root/massa
docker compose up -d --force-recreate functions 2>/dev/null \
  || docker compose up -d --force-recreate edge-functions 2>/dev/null \
  || { echo '★ compose 로 재생성 실패 — 서비스 이름을 확인하세요'; docker compose config --services; exit 1; }
sleep 8

# ── 4) 키 파일 삭제 ──────────────────────────────────────────
shred -u "$SRC" 2>/dev/null || rm -f "$SRC"
echo "키 파일 삭제됨"

# ── 5) 동작 확인 ─────────────────────────────────────────────
echo '--- 컨테이너에 변수가 들어갔는지 (길이만) ---'
docker exec massa-edge-functions sh -c 'echo "GOOGLE_MAPS_KEY 길이: ${#GOOGLE_MAPS_KEY}"'
echo '--- 검색 시험 (Lotte Hotel Hanoi) ---'
ANON=$(grep '^ANON_KEY=' "$ENVF" | cut -d= -f2-)
curl -s -X POST https://massa.moahagwon.com/functions/v1/places-search \
  -H "Authorization: Bearer $ANON" -H 'Content-Type: application/json' \
  -d '{"q":"Lotte Hotel Hanoi","lang":"en"}' | head -c 600
echo ''
echo '=== 완료 ==='
