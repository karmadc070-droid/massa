#!/bin/sh
# 대시보드를 PostgREST(=브라우저가 실제로 쓰는 길)로 불러 본다.
# 관리자 토큰을 잠깐 만들어 쓴다. 비밀키는 화면에 찍지 않는다.
set -e
cd /root/massa

python3 - <<'PY'
import base64, hmac, hashlib, json, time, subprocess, urllib.request, urllib.error

def env(k):
    for line in open('/root/massa/.env'):
        if line.startswith(k + '='):
            return line.split('=', 1)[1].strip()
    raise SystemExit(k + ' 가 .env 에 없다')

secret = env('JWT_SECRET')

def psql(sql):
    return subprocess.run(
        ['docker', 'exec', 'massa-db', 'psql', '-U', 'postgres', '-d', 'postgres', '-A', '-t', '-c', sql],
        capture_output=True, text=True).stdout.strip()

def token(uid, role='authenticated'):
    b = lambda o: base64.urlsafe_b64encode(json.dumps(o, separators=(',', ':')).encode()).rstrip(b'=')
    head = b({'alg': 'HS256', 'typ': 'JWT'})
    body = b({'sub': uid, 'role': role, 'aud': 'authenticated',
              'iat': int(time.time()), 'exp': int(time.time()) + 300})
    msg = head + b'.' + body
    sig = base64.urlsafe_b64encode(hmac.new(secret.encode(), msg, hashlib.sha256).digest()).rstrip(b'=')
    return (msg + b'.' + sig).decode()

def call(jwt, label):
    req = urllib.request.Request(
        'https://api.moahagwon.com/rest/v1/rpc/admin_dashboard',
        data=json.dumps({'p_bucket': 'month', 'p_periods': 3}).encode(),
        headers={'Content-Type': 'application/json', 'apikey': env('ANON_KEY'),
                 'Authorization': 'Bearer ' + jwt})
    try:
        r = urllib.request.urlopen(req, timeout=20)
        d = json.loads(r.read())
        print(f'  {label}: HTTP {r.status} · 버킷 {len(d["series"])}개 · '
              f'회원 {d["now"]["members"]} · 수수료율 {d["fee_rate"]}')
    except urllib.error.HTTPError as e:
        print(f'  {label}: HTTP {e.code} · {e.read().decode()[:160]}')

admin = psql("select id from public.profiles where role='admin' limit 1")
cust  = psql("select id from public.profiles where role='customer' limit 1")

print('=== PostgREST 경유 호출 ===')
call(token(admin), '관리자 (200 이어야 한다)')
call(token(cust),  '일반 고객 (400/403 이어야 한다)')

# 비로그인(anon)
req = urllib.request.Request(
    'https://api.moahagwon.com/rest/v1/rpc/admin_dashboard',
    data=b'{}', headers={'Content-Type': 'application/json',
                         'apikey': env('ANON_KEY'), 'Authorization': 'Bearer ' + env('ANON_KEY')})
try:
    r = urllib.request.urlopen(req, timeout=20)
    print('  비로그인: HTTP', r.status, '★ 열려 있으면 안 된다')
except urllib.error.HTTPError as e:
    print(f'  비로그인 (404/403 이어야 한다): HTTP {e.code}')

# track_visit 은 비로그인도 되어야 한다
req = urllib.request.Request(
    'https://api.moahagwon.com/rest/v1/rpc/track_visit',
    data=json.dumps({'p_device': 'apitest-1', 'p_platform': 'web', 'p_lang': 'ko'}).encode(),
    headers={'Content-Type': 'application/json',
             'apikey': env('ANON_KEY'), 'Authorization': 'Bearer ' + env('ANON_KEY')})
try:
    r = urllib.request.urlopen(req, timeout=20)
    print('=== track_visit (비로그인도 되어야 한다):', r.status, '===')
except urllib.error.HTTPError as e:
    print('=== track_visit ★ 실패:', e.code, e.read().decode()[:160], '===')
PY

echo "=== 기록된 방문 ==="
docker exec massa-db psql -U postgres -d postgres -c \
  "select visit_date, device_id, platform, lang, is_member from public.app_visit order by created_at desc limit 5;"
echo "=== API TEST DONE ==="
