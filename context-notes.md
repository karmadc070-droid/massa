# massa 작업 컨텍스트 노트

작업 중 내린 결정과 그 근거를 기록한다. 다음 세션은 이 문서와 checklist.md부터 읽는다.

## 2026-08-29 · API 도메인을 moahagwon.com 서브도메인으로

**결정**: 새 도메인을 사지 않고 기존 `moahagwon.com`의 서브도메인(`api.moahagwon.com`)을 massa API에 쓴다.

**근거**
- 현재 API 주소 `massa.141-164-46-88.sslip.io`는 무료 와일드카드 DNS라 **AAAA 레코드가 없다**. Apple 심사는 IPv6 환경에서 이뤄지며, 2차 리젝의 2.1(a)(로그인 무한 대기)의 원인 후보로 남아 있었다.
- `moahagwon.com`은 이미 Cloudflare DNS를 쓰고 있어 서브도메인 추가에 비용도 대기 시간도 없다.
- 브랜드가 다르지만 API 주소는 실사용자에게 노출되지 않는다.

**Cloudflare 프록시는 끈다(DNS only)**
- Supabase Realtime은 WebSocket, Storage는 대용량 업로드를 쓴다. Cloudflare 프록시는 이 둘에 제약(타임아웃·업로드 상한)이 있어 오작동 위험이 있다.
- 프록시를 끄면 A·AAAA를 직접 등록하게 되고, TLS는 Caddy가 Let's Encrypt로 자동 발급한다. IPv6 목적은 그대로 달성된다.

## 2026-08-29 · 관리자·파트너 기능을 웹으로 분리

**결정**: 앱은 고객 전용으로 두고, 관리자 13개 + 파트너 10개 화면을 `admin.moahagwon.com`으로 옮긴다.

**근거**
- 앱에 운영 기능이 섞여 있으면 심사관이 볼 수 없는 화면이 생겨 Guideline 2.3.1(숨겨진 기능) 소지가 있다. 지금은 demo 계정에 파트너 권한을 줘서 피하고 있는데, 이 방식은 데모 계정이 노출되면 일반 사용자도 운영 화면에 접근하게 된다(실제로 1.0에서 로그인 창에 데모 계정이 노출돼 있었다).
- 앱 용량·복잡도가 줄고 고객 플로우 검증이 쉬워진다.
- 운영자는 PC에서 쓰는 편이 실제로 편하다.

**한 번에 옮기지 않는 이유**
- index.html 3,950줄에서 23개 화면을 들어내는 작업이라 한 번에 하면 회귀를 잡기 어렵다. 관리자 → 파트너 순서로 나누고 각 단계마다 문법 검사와 고객 플로우 확인을 넣는다.

## 2026-08-29 · 채팅을 예약 이후로 제한

**결정**: 제공자 프로필에서 바로 채팅하지 못하게 하고, 예약이 있는 상대와만 채팅한다.

**근거**: 예약 전에 채팅이 열리면 앱을 거치지 않는 직거래로 이어진다. 제공자 연락처를 관리자 전용으로 돌린 것과 같은 목적이다.

**구현**: 버튼을 숨기는 대신 `openChat` 진입부에서 bookings를 조회해 막는다(취소 건 제외). 진입 지점이 프로필·예약완료·예약내역 세 곳이라 한 곳에서 검사해야 우회가 없다. 예약 완료 화면과 예약 내역 카드에 채팅 버튼을 새로 넣었다.

## 2026-08-29 · A 단계 실행 결과

- `api.moahagwon.com` A(141.164.46.88) + AAAA(2401:c080:1c02:7e6:5400:6ff:fe98:627f), 둘 다 DNS only
- Caddy `/root/Caddyfile`에 블록 추가 후 `docker exec caddy caddy reload` — 무중단. 기존 sslip.io 블록은 그대로 두어 구버전 앱 호환
- 검증: IPv4/IPv6 모두 401(정상), 로그인 255ms(기존 737ms)
- DB URL 치환 50건. **어느 컬럼인지 모른 채 UPDATE를 쓰지 않고** information_schema로 text·ARRAY 컬럼을 훑었더니 `providers.photo_urls`(배열) 25건이 추가로 나왔다. 추측했으면 절반을 놓쳤을 것

## 2026-08-29 · B0 단계에서 겪은 함정 세 가지

1. **스크립트 스코프**: `guardConsole`을 1136줄의 일반 `<script>`에 넣었더니 `refreshSession is not defined`. 앱 로직은 전부 1357줄의 `<script type="module">` 안에 있다. 모듈은 별도 스코프이므로 **관련 코드는 반드시 모듈 안에** 넣어야 한다.
2. **raw.githubusercontent.com 캐시**: 푸시 직후 배포해도 최대 5분간 옛 파일이 내려온다. 배포 스크립트는 `codeload.github.com/.../tar.gz/refs/heads/main`으로 받는다(항상 최신).
3. **try 블록 안의 가드**: `load()` 내부 try에 권한 검사를 넣었더니 실행되지 않았다. 앞선 await에서 흐름이 갈리면 건너뛴다. `(async () => { if (await guardConsole()) load(); })()` 처럼 **호출 자체를 감싸는** 편이 확실하다.

또한 noVNC 콘솔은 Shift가 안 먹으므로 `&&`를 쓸 수 없다(`77`로 깨진다). 명령은 한 줄씩 따로 입력한다.

## 2026-08-29 · 비밀번호 재설정에 massa.moahagwon.com 을 새로 만든 이유

**결정**: 재설정 페이지를 `admin.moahagwon.com`에 얹지 않고 `massa.moahagwon.com`을 새로 만들었다.

**근거**
- 재설정 메일은 고객에게도 간다. 링크가 `admin.`으로 시작하면 피싱처럼 보인다.
- Vercel 임시 도메인(`massa-seven.vercel.app`)은 git 미연동이라 갱신이 안 되고 있었다. 같은 VPS에서 고객용 웹앱까지 서빙하면 C2 항목도 함께 해결된다.
- A 레코드 하나 + Caddy 블록 하나로 끝나 비용도 복잡도도 늘지 않는다.

**GoTrue 쪽 필수 설정**: `GOTRUE_SITE_URL`과 `GOTRUE_URI_ALLOW_LIST`에 이 주소가 없으면 `resetPasswordForEmail`의 `redirectTo`가 무시되고 SITE_URL로 돌아간다. 지금 SITE_URL은 옛 Vercel 주소라 반드시 함께 바꿔야 한다.

## 2026-08-29 · Resend DNS는 수동 입력하지 말 것

Resend 도메인 화면의 DKIM 값은 UI에서 `p=MIGfMA0GCSqG[…]SIb3...` 처럼 중간 생략 표시가 붙어 나온다. 실제로 생략된 문자가 없는데도 `[…]`가 보이므로, 눈으로 읽어 옮기면 틀릴 위험이 있다. Cloudflare를 쓰면 **Auto configure** 버튼이 DKIM·MX·SPF 3개를 직접 넣어주므로 그쪽을 쓴다. 버튼을 눌러도 화면이 바로 안 바뀌고 "Temporarily unavailable"이 뜰 수 있는데, Cloudflare DNS 목록을 열어보면 이미 들어가 있다.

## 2026-08-29 · VPS 접속은 noVNC 말고 SSH를 쓸 것

**결정**: 앞으로 VPS 작업은 Vultr noVNC 대신 SSH로 한다.

```
& "C:\Program Files\Git\usr\bin\ssh.exe" -i "$env:USERPROFILE/.ssh/erp_vultr" -o BatchMode=yes root@141.164.46.88 '명령'
```

**근거 — noVNC에서 실제로 겪은 사고**
- Shift 조합이 깨진다(`+`→`=`, `_`→`-`). `dig +short`가 `dig =short`가 되고 `resend._domainkey`가 `resend.-domainkey`가 됐다.
- 사이드바의 **Ctrl 토글은 눌린 채로 유지된다**. 이걸 모르고 이어서 타이핑했더니 `clear`가 Ctrl+C/L/E/A/R로 들어가 로그인 세션이 끊겼고, Ctrl+S가 걸려 화면 출력이 멈췄다(Ctrl+Q로 복구).
- 그 뒤 키 입력 채널 자체가 죽어 사용자가 직접 타이핑해도 반응하지 않았다. 탭을 새로 열어도 마찬가지였다.

**Windows의 `C:\WINDOWS\System32\OpenSSH\ssh.exe`는 이 PC에서 아무 출력 없이 exit 255로 끝난다.** `ssh -V`조차 안 된다. Git 번들 ssh(`C:\Program Files\Git\usr\bin\ssh.exe`)는 정상 동작한다. 키는 `~/.ssh/erp_vultr`.

## 2026-08-29 · GoTrue 설정은 .env 변수명을 compose에서 확인하고 쓸 것

`docker-compose.yml`이 `GOTRUE_SITE_URL: ${SITE_URL}` 처럼 **다른 이름으로 매핑**한다. `.env`에 `GOTRUE_SITE_URL=`을 써도 읽히지 않는다. 실제로 이 실수로 1차 적용 때 SMTP만 바뀌고 SITE_URL은 옛 Vercel 주소 그대로였다.

| .env 에 쓸 이름 | 컨테이너 안 이름 |
| --- | --- |
| `SITE_URL` | `GOTRUE_SITE_URL` |
| `ADDITIONAL_REDIRECT_URLS` | `GOTRUE_URI_ALLOW_LIST` |
| `ENABLE_EMAIL_AUTOCONFIRM` | `GOTRUE_MAILER_AUTOCONFIRM` |
| `SMTP_*` | `GOTRUE_SMTP_*` |

검증은 `.env`가 아니라 `docker exec massa-auth env | grep GOTRUE_` 로 해야 한다.

## 2026-08-29 · 다국어를 CSS 클래스 순회에서 텍스트 노드 순회로 바꾼 이유

**문제**: 옛 `applyLang` 은 `I18N_SEL` 에 적힌 클래스만 훑고, 그마저도 `if (el.querySelector('*')) return;` 로 **자식 태그가 있으면 통째로 건너뛰었다**. 게다가 호출 지점이 4곳뿐이라 innerHTML 로 나중에 그려지는 목록·오버레이는 아예 번역 대상이 아니었다. "되는 것과 안 되는 것이 섞여 있다"는 증상의 원인이 이것이다.

**해결**: `translateTree()` 가 텍스트 노드를 전부 훑고, 각 노드에 한국어 원문을 `n.__ko` 로 보관한다. 여기에 `MutationObserver`(60ms 디바운스)를 붙여 새로 그려진 DOM 도 따라간다. 클래스에 의존하지 않으므로 오버레이든 동적 목록이든 상관없다.

**주의 두 가지**
1. 배너 제목·탭바·언어 버튼처럼 **전용 사전으로 따로 채우는 요소는 반드시 제외**해야 한다. 안 그러면 `__ko` 에 저장된 옛 값으로 서로 덮어쓴다. 단 `.banner` 통째로 빼면 그 안의 pill 까지 번역이 안 되므로 `.banner .bt, .banner .bd` 처럼 좁혀야 한다.
2. `alert`/`confirm`/`prompt` 는 DOM 이 아니므로 옵저버가 못 잡는다. 함수 자체를 래핑해 `T()` 를 태웠다 — 호출부 61곳을 고치지 않아도 된다.

## 2026-08-29 · 조합형 문구는 T() 말고 span 으로 쪼갤 것

`'아로마·스웨디시 · 한국어 가능 · 미딩 권역'` 같은 문장은 통째로 사전에 넣을 수 없다. 처음엔 생성 시점에 `T()` 로 감쌌는데, **카드를 만든 시점의 언어로 굳어** 언어를 바꿔도 그대로였다(목록을 다시 그리지 않으므로).

각 조각을 `<span>` 으로 감싸면 텍스트 노드가 나뉘어 사전에 개별로 걸리고, `translateTree` 가 그 자리에서 바꿔 준다. 다시 그릴 필요가 없다.

```js
// 나쁨 — 만든 시점 언어로 고정된다
const spec = list.map(s => T(TYPE_KO[s])).join('·');
// 좋음 — 언어를 바꾸면 그 자리에서 함께 바뀐다
const spec = list.map(s => '<span>' + TYPE_KO[s] + '</span>').join('·');
```

`T()` 는 DOM 밖(alert 문구, prompt 질문)에만 쓴다.

## 2026-08-29 · 사전 점검은 항목 단위 정규식으로

DICT 는 한 줄에 여러 항목이 들어 있는 줄이 있다. 줄 단위 정규식(`^\s*'key':\s*\[(.*)\]$`)으로 검사하면 **첫 항목만 보고 나머지를 놓쳐서** "zh/ja 누락 0개"라는 잘못된 결과가 나온다. 실제로는 56개가 비어 있었다. 항목 단위 패턴으로 세야 한다.

```python
re.compile(r"'((?:[^'\\]|\\.)*)'\s*:\s*\[((?:\s*'(?:[^'\\]|\\.)*'\s*,?)*)\]")
```

번역을 추가할 때는 `scripts/i18n-add.py` 를 고쳐 다시 실행한다. 같은 키는 덮어쓰므로 몇 번을 돌려도 결과가 같다.

## 2026-08-29 · 번역한 텍스트에서 숫자를 긁어내지 말 것

날짜 칩 마크업이 `<div class="day"><span class="dow">수</span>10</div>` 인데, 날짜를 이렇게 읽고 있었다.

```js
el.textContent.replace(/\D/g, '')   // '수10' → '10'
```

요일을 번역하자 베트남어 수요일이 `T4` 가 되면서 `T410` → **`410`** 이 됐다. 확인 화면에 `06/410` 이 찍혔고, 더 나쁜 건 `submitBooking()` 도 같은 코드를 써서 **잘못된 날짜로 예약이 저장될 수 있었다**.

교훈: 화면에 보이는 문자열은 번역되면 내용이 바뀐다. 거기서 값을 파싱하면 안 된다. `selectedDayNum()` 처럼 라벨 요소를 빼고 읽거나, 애초에 `data-*` 속성에 값을 따로 두는 편이 안전하다. 다국어를 붙일 때는 **문자열을 파싱하는 코드부터 찾아볼 것**.

## 알려진 함정 (반복 확인됨)

- **GitHub 푸시**: 저장소 소유자는 `karmadc070-droid`, PC 자격증명은 `parkdongchun-77`. 협업자로 초대·수락해 해결함. push가 멈추면 대기 중인 git 프로세스를 죽이고 재시도.
- **Codemagic 빌드 번호**: `app-store-connect get-latest-*`가 항상 0을 반환해 중복 실패. `$PROJECT_BUILD_NUMBER` 사용 중.
- **마케팅 버전**: 출시된 버전 트레인은 닫힌다. `capacitor/package.json`의 version을 올려야 한다.
- **ASC 웹 UI**: `/apps/<id>/distribution/...`로 직접 열면 렌더링 안 됨. `/apps`부터 SPA 내부 링크를 클릭할 것.
- **CSS 우선순위**: `#id { display: ... }`가 `.screen { display:none }`을 덮어써 비활성 화면이 남는 사고가 있었다(#chat). 화면 전용 스타일은 반드시 `#id.on`으로 쓸 것.

## 2026-08-30 · 결제창을 여는 페이지를 웹에 따로 둔다

**결정**: 토스 결제창을 앱에서 직접 띄우지 않고, `pay-start.html` 이라는 웹 페이지가 띄우게 한다.
앱은 그 주소를 앱 내 브라우저(SFSafariViewController)로 연다.

**근거**
- 토스 SDK 의 `requestPayment` 는 현재 페이지를 토스 도메인으로 **이동**시킨다.
  Capacitor 웹뷰는 `capacitor://localhost` 라, 여기서 이동하면 앱 껍데기 자체를 벗어난다.
- 사파리로 나가버리면 돌아올 방법이 없고 App Store 가이드라인 4 소지도 생긴다.
- 웹과 앱이 같은 페이지를 쓰므로 결제 코드 경로가 하나로 유지된다. 모아학원처럼 iOS 결제를 꺼둘 필요가 없다.

**대안으로 검토한 것**: 앱 안에 토스 SDK 를 넣고 결제창만 새 창으로 — 웹뷰에서 팝업 차단·복귀 문제가 그대로 남아 버렸다.

## 2026-08-30 · 앱 복귀는 파라미터가 아니라 호스트로 가른다

**발견한 버그**: `native.js` 가 `searchParams.get("code")` 로 결제 복귀를 판별하고 있었다.
그런데 **OAuth PKCE 로그인도 `code=` 를 달고 돌아온다**(`massa://auth?code=...`).
구글 로그인 키가 들어오는 순간 로그인이 결제 처리로 새게 되어 있었다.

**수정**: `massa://auth` / `massa://pay` 의 **호스트**로 가른다. 5개 URL 케이스로 검증했다.

**교훈**: 딥링크는 목적지를 경로에 박아야 한다. 쿼리 파라미터는 서로 다른 흐름이 우연히 같은 이름을 쓴다.

## 2026-08-30 · 토스 결제 수단은 켜기 전까지 숨긴다

`TOSS_ENABLED = false` 상수 하나로 결제 시트에서 감춘다. 키가 없으면 결제창이 뜨지 않는데,
눌러도 안 되는 버튼은 App Store 4.0 리젝 사유다. 소셜 로그인에서 이미 한 번 겪었다.
토스 키를 VPS 에 넣는 날 이 상수를 `true` 로 바꾼다.

**남겨둔 것**: 결제 시트의 기존 `카드`·`QR`·`은행 이체` 는 PG 연결 없이 `is_paid=true` 로 찍는
자리표시자다. 이번 작업 범위 밖이라 건드리지 않았다. 토스가 살아나면 이것들의 처리를 따로 정해야 한다.
