#!/bin/sh
# app.massaviet.com 에 assetlinks.json 을 둔다.
# 새 TWA 가 이 주소를 열 때 주소창 없이 전체화면으로 뜨려면 이 파일이 있어야 한다.
# 지문은 기존 서명키(android-package/signing.keystore)의 것이다. 재빌드해도 같은 키로 서명하므로 바뀌지 않는다.
set -e

# app.massaviet.com 이 어느 디렉터리를 서빙하는지부터 확인한다. 엉뚱한 곳에 넣으면 404 다.
echo '=== Caddy 설정에서 app.massaviet.com 블록 ==='
awk '/^app\.massaviet\.com/,/^}/' /root/Caddyfile | sed 's/^/  /'

ROOT=$(awk '/^app\.massaviet\.com/,/^}/' /root/Caddyfile | grep -oE 'root \* [^ ]+' | awk '{print $3}')
[ -n "$ROOT" ] || { echo '  root 를 못 찾았다 — reverse_proxy 일 수 있다. 중단'; exit 1; }
echo "  문서 루트: $ROOT"

mkdir -p "$ROOT/.well-known"
cat > "$ROOT/.well-known/assetlinks.json" <<'EOF'
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "app.massa.hanoi",
    "sha256_cert_fingerprints": ["7B:AC:10:B2:1C:AC:F7:69:8C:D1:5F:3B:DD:87:A3:FF:1C:C4:B4:52:F9:DF:7E:1D:3E:56:56:9E:89:B0:19:5A"]
  }
}]
EOF

echo ''
echo '=== 확인 ==='
printf '  상태        %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://app.massaviet.com/.well-known/assetlinks.json)"
printf '  Content-Type %s\n' "$(curl -s -o /dev/null -w '%{content_type}' --max-time 20 https://app.massaviet.com/.well-known/assetlinks.json)"
printf '  지문 일치   %s\n' "$(curl -s --max-time 20 https://app.massaviet.com/.well-known/assetlinks.json | grep -c '7B:AC:10:B2')"
echo '  --- 참고: 지금 쓰는 Vercel 쪽 ---'
printf '  vercel 상태 %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://massa-seven.vercel.app/.well-known/assetlinks.json)"
