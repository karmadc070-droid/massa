# massa 작업 체크리스트

## A. API 도메인 교체 (sslip.io → moahagwon.com 서브도메인)

목표: 앱이 임시 도메인 대신 정식 도메인을 바라보게 하고, IPv6 미지원 문제를 없앤다.

- [x] A1. Cloudflare에 `api.moahagwon.com` A+AAAA 추가 (DNS only) — 2026-08-29 완료
- [x] A2. Caddy `/root/Caddyfile`에 `api.moahagwon.com → localhost:8002` 추가, 무중단 reload — 완료
- [x] A3. IPv4/IPv6 모두 401 응답 확인 (인증서 자동 발급됨), 기존 sslip.io도 정상 — 완료
- [x] A4. index.html SUPABASE_URL 교체 → 로그인 255ms·목록 조회 정상 확인 — 완료
- [x] A5. DB URL 치환: providers.photo_url 25건 + providers.photo_urls(배열) 25건 = 50건 — 완료
- [x] A6. 심사 정보에는 서버 URL이 없어 갱신 불필요 — 확인함
- [x] A7. build 14로 1.0.1 심사 제출 완료 (2026-08-29) → 남은 verify: TestFlight 실기기에서 로그인·예약 동작

## A2. 비밀번호 재설정 메일 (Resend)

목표: 비밀번호를 잊은 사용자가 메일로 재설정할 수 있게 한다. GoTrue의 SMTP가 더미라 지금은 메일이 안 나간다.

- [x] A2-1. Resend 가입·도메인 `moahagwon.com` 추가, Auto configure로 Cloudflare에 DKIM·MX·SPF 등록 — 2026-08-29
- [x] A2-2. `massa.moahagwon.com` A 레코드(DNS only) + Caddy 정적 서빙 → `/srv/massa-web` (index.html, reset.html)
- [x] A2-3. `reset.html` 작성 (메일 링크로 들어와 새 비밀번호 설정) → verify: 200 응답 + 토큰 없이 열면 "만료" 안내 확인함
- [x] A2-4. index.html·admin.html 로그인창에 "비밀번호를 잊으셨나요?" 추가 → verify: 모듈 문법 검사 통과
- [x] A2-5. Resend API 키 발급 → VPS `/root/resend.key` (600)
- [x] A2-6. `scripts/vps-setup-smtp.sh` 실행 → verify: auth 컨테이너 env에 `GOTRUE_SMTP_HOST=smtp.resend.com`, `GOTRUE_SITE_URL=https://massa.moahagwon.com`, `GOTRUE_URI_ALLOW_LIST` 반영 확인함
- [x] A2-7. 실제 발송 확인 → Resend 로그 **Delivered**, 발신 `"massa" <massa@moahagwon.com>`
- [x] A2-8. 메일 링크 클릭 → `reset.html`이 recovery 세션을 받아 정상 폼 표시 (만료 안내 아님) — 전 과정 1회 성공

남은 개선

- [ ] A2-9. 메일 템플릿 한국어화 (현재 제목 "Reset Your Password", 본문 영문 기본 템플릿)
- [ ] A2-10. Resend API 키 회전 (작업 중 화면·대화에 값이 노출됨)

## B. 관리자·파트너 기능 웹 이전 (23개 화면)

목표: 앱은 고객 전용으로 남기고, 운영 기능은 `admin.moahagwon.com`에서 관리자 로그인 후 사용한다.

### B0. 준비 — 완료 (2026-08-29)
- [x] B0-1. `admin.html` 생성 (index.html 복사본 + `guardConsole` 권한 검사) → 미로그인 시 차단 화면 확인함
- [x] B0-2. 배포: VPS Caddy 정적 서빙. `admin.moahagwon.com` → `/srv/massa-admin`
  - DNS A 레코드 등록(DNS only), Caddy 블록 추가, noindex 헤더 포함
  - 배포 스크립트: `scripts/vps-deploy-admin.sh` (codeload로 최신 커밋 취득 + 모듈 스코프 검증)

### B1. 관리자 화면 13개 이전 — 완료 (2026-08-29)
adminApps(심사) · adminStats · adminReports · adminMembers · adminSettlement · adminAds · adminFraud · adminBookings · adminProviders · adminFee · adminCoupons · adminSales · adminCountry
- [x] B1-1. admin.html 에 13개 화면·로더 전부 존재함을 확인 (앱에서 지우기 전에 먼저 확인함)
- [x] B1-2. 앱에서 638줄 삭제 → verify: 문법 통과, 화면 34개 남음, div 균형 408/408, 남은 admin 참조 0

### B2. 파트너 화면 10개 이전 — 완료 (2026-08-29)
partnerBookings · partnerRevenue · partnerSchedule · partnerEvents · partnerStaff · partnerSettle · partnerChat · partnerGps · partnerAi · partnerAiBiz
- [x] B2-1. 앱에서 534줄 삭제 → verify: 문법 통과, 고객 화면 24개만 남음, div 356/356
- [x] B2-2. `isPartner`·`rowVis`·`canReview`·`FEE_RATE`/`DUE_DAYS` 등 고아 코드 정리
- [x] B2-3. 실제 배포 후 브라우저 확인 → 홈·목록 정상, 콘솔 오류 0
- index.html 334KB → 224KB

### B3. 마무리
- [ ] B3-1. demo 계정 파트너 권한 정리 여부 결정 (심사용으로 필요한지)
- [ ] B3-2. 앱 빌드·제출 → verify: 실기기에서 계정 화면에 운영 메뉴가 없음
- [ ] B3-3. 인계서(IOS_진행상황.md) 갱신

## D. 다국어 (한국어·베트남어·영어·중국어·일본어)

방침: 고객 앱은 5개 언어 전부(알림창 포함), 운영 콘솔은 한국어·베트남어.

### D1. 엔진 교체 — 완료 (2026-08-29)
- [x] D1-1. 정해진 CSS 클래스 순회 → **텍스트 노드 전체 순회**(`translateTree`)로 교체. 자식 태그가 있으면 건너뛰던 문제 해소
- [x] D1-2. `MutationObserver` 추가 → innerHTML 로 나중에 그려지는 목록·오버레이도 자동 번역
- [x] D1-3. `alert`·`confirm`·`prompt` 래핑 → 호출부 61곳을 고치지 않고 한 번에 번역 경로에 태움
- [x] D1-4. 선택한 언어를 localStorage 에 저장, 없으면 기기 언어를 따름 (이전에는 새로고침마다 한국어로 되돌아갔다)
- [x] D1-5. `trOne` 의 빈 문자열 폴백 버그 수정 (`e[idx] || ...` → undefined/null 만 폴백)

### D2. 사전 보강 — 완료
- [x] D2-1. DICT 202개 → **332개**, 중국어·일본어 누락 **56개 → 0개**
- [x] D2-2. TITLE_I18N 화면 제목 5개 추가 (계정 정보·제공자 등록 신청·지도 검색·지역 선택·채팅)
- [x] D2-3. 하노이 지명 7곳을 현지 표기로 (미딩 → Mỹ Đình 등)
- [x] D2-4. 재실행 가능한 스크립트로 관리 → `scripts/i18n-add.py`

### D3. 조합형 문구 — 완료
- [x] D3-1. 카드·목록의 조합 문구를 `<span>` 조각으로 분리 → 언어를 바꾸면 다시 그리지 않아도 그 자리에서 바뀜
- verify: 미번역 한국어 텍스트 노드 **190개 → 6~9개** (남은 것은 confirm/done 의 와이어프레임 더미로, 실제 예약 시 데이터로 대체됨)
- verify: 베트남어·일본어 실화면 확인 — 목록·계정 화면 전체 번역됨

### D4. 운영 콘솔 — 완료
- [x] D4-1. admin.html 에 같은 엔진·사전 이식, 언어 선택을 한국어·베트남어로 제한
- [x] D4-2. `guardConsole` 차단 화면도 번역 (load 보다 먼저 실행되므로 언어 복원을 IIFE 시작부에도 넣음)

### D5. 검증 — 완료 (2026-08-29)
- [x] D5-1. 예약 플로우 4개 화면(코스·시간·위치·확인)을 4개 언어로 밟음 → **남은 한국어는 확인 화면 요약 3줄뿐**이고 그건 i18n 문제가 아니라 아래 E1 버그
- [x] D5-2. alert/confirm 문구 23개를 사전에 등록. 뒤에 값이 붙는 문구(`저장 실패: ...`)는 `Tmsg()` 가 접두사만 바꾸도록 처리 → verify: 4개 언어 번역 결과 확인함
- [x] D5-3. 코스 카드의 `· 90분`, `(약 N원)`, 취소 안내의 시간 수치 등 조합 문구를 span 으로 분리

## E. 검증 중 발견한 결함 — 모두 수정 완료 (2026-08-29)

### E1. 예약 확인 화면이 선택 내용을 반영하지 않던 문제
`#confirm` 요약 3줄이 마크업에 하드코딩돼 있어, 다른 제공자·시간·호텔을 골라도 `Linh N. / 6월 7일(일) 20:00 / 롯데호텔 하노이 2104호` 가 그대로 보였다. (`submitBooking()` 은 선택값을 정확히 저장하므로 DB 는 정상이었고 화면만 어긋났다.)
- [x] E1-1. `fillConfirm()` 추가 → 서비스·제공자·날짜·장소·금액을 실제 선택값으로 채운다. 번역 조각은 span 으로 감쌈
- verify: 두 번째 제공자 + 다른 코스 + 수요일 14:30 + Grand Plaza Hanoi 1503 으로 4개 언어 확인 — 전부 정확히 반영됨

### E2. 위치 화면 호텔 입력란의 한국어 기본값
- [x] E2-1. `value="롯데호텔 하노이 (Ba Dinh)"` → `placeholder="예) 롯데호텔 하노이"`
- [x] E2-2. 기본값을 없앤 탓에 빈 채로 예약될 수 있어 `submitBooking()` 에 입력 검증 추가

### E3. 요일 번역이 날짜 숫자에 섞이던 버그 — 가장 위험했던 것
날짜 칩에서 `textContent.replace(/\D/g,'')` 로 날짜를 읽는데, 요일 라벨을 번역하자 **베트남어 수요일 `T4` 의 숫자 4 가 섞여** `06/10` 이 `06/410` 이 됐다.
- 확인 화면 표시뿐 아니라 **`submitBooking()` 의 저장 경로도 같은 코드**여서, 베트남어 사용자는 잘못된 날짜로 예약될 수 있었다.
- [x] E3-1. `selectedDayNum()` 을 만들어 `.dow` 를 뺀 텍스트에서만 숫자를 읽도록 수정, 두 곳 모두 교체
- verify: 4개 언어 모두 `06/10` 으로 정확히 나옴

## C. 기타 남은 일
- [ ] C1. build 12 실기기 로그인 확인 (2.1a 근본 원인 확정)
- [ ] C2. Vercel 웹사이트 최신 배포 (현재 구버전, git 미연동)
- [ ] C3. VPS DB 논리 백업(pg_dump 정기) 설정 — 서버 스냅샷 백업은 Vultr에서 Enabled 확인됨
- [ ] C4. Google Play 프로덕션 신청 (14일 요건, 현재 5일차 · 테스터 12명 충족)
- [ ] C5. Zalo 로그인 + Sign in with Apple (Zalo 계정 인증 후)

### D6. 동적 화면 추가 보강 (2026-08-29)
정적 마크업만 훑던 초기 점검이 **데이터를 불러와야 그려지는 화면**을 놓쳤다. 사용자가 프로필 상세 스크린샷으로 지적해 발견함.
- [x] D6-1. 제공자 프로필 상세 32개 문구 → 사전 등록 + 조합 문구(주소·리뷰 수·차단 토글) span 분리
- [x] D6-2. 알림 화면 6개 문구 → `notiAgo()` 의 '분 전/시간 전/일 전' 을 span 으로 분리
- [x] D6-3. 서비스 메뉴 이름 13종(오일 마사지 + 부항 요법 등) 사전 등록
- verify: 프로필 상세 4개 언어 **각 0개** — 미번역 없음
- **교훈**: 다국어 점검은 반드시 해당 화면을 열고 데이터를 로드한 상태에서 해야 한다. 정적 마크업 스캔만으로는 절반만 본다.

## F. 1.0.2 빌드·제출
- [x] F1. 1.0.1 심사 통과 → **출시 완료** (한국·베트남)
- [x] F2. `capacitor/package.json` 1.0.2 로 올림
- [x] F3. Codemagic **build 16** 업로드 성공 (build 15 는 프로필 다국어 수정 전이라 폐기)
- [x] F4. 1.0.2 버전 생성 → build 16 첨부 → 변경사항 작성 → **심사 제출 완료** (상태: 1.0.2 심사 대기 중)

## G. 소셜 로그인 (구글·카카오·애플)

방침: **키가 설정된 provider 만 버튼이 나타난다.** 앱이 `/auth/v1/settings` 를 읽어 판단한다.
예전에 "구글 버튼은 있는데 눌러도 안 됨"으로 Apple 4.0 리젝을 받았기 때문에, 키 없이 버튼이 노출되는 일이 없어야 한다.

### G1. 뼈대 — 완료 (2026-08-29)
- [x] G1-1. GoTrue 에 google·kakao·apple provider 매핑 추가 (docker-compose 12줄 + .env 자리 9개)
- [x] G1-2. 앱에 `loadSocialProviders()` / `renderSocialButtons()` / `socialLogin()` 추가
- [x] G1-3. 네이티브 복귀 처리 — `@capacitor/browser`(앱 내 브라우저) + `@capacitor/app`(appUrlOpen) + `onNativeAuthReturn()`
- [x] G1-4. iOS URL 스킴 `massa://` 등록을 codemagic.yaml 에 추가
- [x] G1-5. 키 발급 안내서 작성 → `소셜로그인_키발급_안내.md`
- verify: 키 없는 지금 → 버튼 **0개**. settings 응답을 켜진 것으로 바꾸면 → **3개**(구글·카카오·애플) 정상 표시

### G2. 키 발급

> 확장 프로그램(DeepSeek AI, 1688-aibuy) 때문에 **실제 마우스 클릭이 카카오 모달을 죽인다.**
> `javascript_tool` 로 pointer/mouse 이벤트를 직접 디스패치하면 통과한다. 구글 콘솔은 배율이 튀므로 ref 사용.

- [x] G2-1. 구글 — 프로젝트 `Massa`(massa-507208) 에 OAuth 구성 + 웹 클라이언트 `massa web` 생성 (2026-08-30)
  - 대상 **외부**, 게시 상태 **프로덕션** (테스트 모드면 등록한 계정만 로그인된다)
  - 리디렉션 `https://api.moahagwon.com/auth/v1/callback`
  - 브랜딩: 홈페이지·개인정보처리방침·약관 URL 등록, 승인된 도메인 `moahagwon.com`
  - ⚠️ 클라이언트 보안 비밀번호는 **생성 직후 1회만** 보인다. 사장님이 복사함
- [x] G2-2. 카카오 — 앱 `massa` (ID 1562938) 생성 (2026-08-30)
  - 카테고리 뷰티 / 회사명 massa / 대표 도메인 `https://massa.moahagwon.com`
  - 카카오 로그인 **ON**, Redirect URI 등록, 클라이언트 시크릿 **ON**(기본값)
  - 앱 아이콘 등록 (저장소 `icons/icon-192.png`) → **비즈 앱 전환의 선행 조건**이었다
  - 사업자 정보 등록 → **비즈 앱 전환 완료** (사장님이 직접 입력)
  - 동의항목 **닉네임 필수 동의**, **이메일 필수 동의 + 수집** (비즈 앱 전에는 `권한 없음`이라 못 켰다)
- [x] G2-3. 애플 — 전부 완료 (2026-08-30)
  - `app.massa.hanoi` 에 **Sign In with Apple 활성화** (프로파일 무효화 경고는 Codemagic 이 매 빌드 재생성하므로 무해)
  - Services ID **`app.massa.hanoi.web`** — Primary `massa hanoi`, Domain `api.moahagwon.com`, Return URL `https://api.moahagwon.com/auth/v1/callback`
  - Key **`massa Sign in with Apple`** (Key ID `884XVUF24R`) → .p8 을 VPS 로 scp → JWT 생성 → .p8·conf 삭제
  - **적용 완료: `/auth/v1/settings` 에서 `apple: true`**
  - Private Email Relay — `moahagwon.com` 등록, 상태 **SPF 통과** (Resend 가 세워둔 SPF 재사용, DNS 추가 작업 없었음)
  - ⚠️ **애플 시크릿 만료 2027-03-01.** 만료 전 `.p8` 로 다시 만들어야 로그인이 끊기지 않는다
  - ⚠️ developer.apple.com 은 App Store Connect 와 **세션이 따로**다. 다시 로그인해야 한다
- [x] G2-4. 애플 시크릿 JWT 생성 스크립트 `scripts/vps-apple-secret.sh` — .p8 을 VPS 안에서만 다루고 끝나면 삭제
  - verify: 테스트 EC 키로 서명 생성 → 공개키 검증 통과, 수명 182.6일(애플 상한 6개월 이내), sig 64바이트

### G3. 키 적용 후
- [x] G3-1. `.env` 채우고 auth 재기동 → **`google: true` / `kakao: true` / `apple: true`** (2026-09-04)
  - verify: 앱에서 버튼 3개 렌더 확인 — `Google로 계속하기` · `카카오로 계속하기` · `Apple로 계속하기`
  - 키 파일은 VPS·로컬 양쪽에서 삭제함
- [x] G3-2. 설정 검증 — 로그인 없이 확인 가능한 부분은 전부 통과 (2026-09-04)
  - 깨끗한 브라우저(세션 없음)로 `/auth/v1/authorize?provider=X` 를 직접 열어 각 provider 화면까지 도달 확인
  - 구글 → 로그인 화면 정상, 등록한 개인정보처리방침·약관 인식됨. `redirect_uri_mismatch`·`invalid_client` 없음
  - 카카오 → 로그인 화면 정상. `KOE006`(리디렉션 불일치)·`KOE101`(잘못된 앱 키) 없음
  - 애플 → "Apple 계정을 사용하여 **massa**에 로그인하십시오". Services ID·Return URL·Primary App ID 연결 확인
  - ⚠️ **남은 미검증 구간**: 실제 계정으로 동의한 뒤의 **토큰 교환**. 여기서만 검증되는 것 — 구글 시크릿 실값,
    카카오 시크릿 실값, **애플 JWT 와 .p8/Key ID 짝**. 실계정 로그인 1회로 확인해야 한다
- [ ] G3-3. iOS 빌드 올려 실기기에서 `massa://` 복귀 검증 — **build 17 진행 중 (1.0.3)**
- [ ] G3-4. 세 개 다 켠 상태로 심사 제출 (**애플 없이 구글·카카오만 켜서 iOS 제출하면 4.8 리젝**)

## I. 1.0.3 빌드·제출 (소셜 로그인)

- [x] I1. 1.0.2 출시 확인 — App Store 조회 API 로 `version 1.0.2`, `2026-08-30` 출시 확인
- [x] I2. `capacitor/package.json` 1.0.3 으로 올림
- [x] I3. 빌드 전 점검 — 소셜 코드 7곳 존재, `CFBundleURLSchemes` 등록 단계 존재,
  `TOSS_ENABLED=false`(토스 숨김 유지), native.js 호스트 라우팅 수정 반영
- [ ] I4. Codemagic **build 17** 결과 확인 → TestFlight 업로드
- [ ] I5. 실기기에서 소셜 로그인 3종 + `massa://` 복귀 검증
- [ ] I6. 1.0.3 버전 생성 → 변경사항 작성 → 심사 제출

> ⚠️ **구글 시크릿 함정.** 구글 콘솔은 생성 후 시크릿을 `****`로 가려서 보여준다.
> 그 표시값(8자)을 그대로 복사해 넣으면 버튼은 뜨는데 로그인이 실패한다 — 4.0 리젝을 부르는 상태다.
> 실제 값은 `GOCSPX-` 로 시작하는 35자다. 잃어버렸으면 `보안 비밀번호 추가` 로 새로 만들면 된다(기존 것은 유지된다).
> 적용 전에 **길이와 `*` 포함 여부를 반드시 확인할 것.**

## H. 토스 선불 결제

방침: 후불(현장 결제)은 그대로 두고 **선불 카드 결제를 선택지로 추가**한다. 상세는 `결제-연동-계획.md`.

- [x] H1(P1). DB — `payment_transactions` 16컬럼, `payment_method` enum 에 `toss`, RLS 2개
- [x] H2(P2). Edge Function `toss-payment` — create / confirm / cancel. 배포·8항목 검증 완료
- [x] H3(P3). 웹 중계 페이지 2개 (2026-08-30)
  - `pay-start.html` — 토스 SDK 로 결제창을 연다. 5개 언어 안내문
  - `pay-return.html` — 앱발 결제(`native=1`)는 `massa://pay` 로 되던지고, 웹은 그 자리에서 승인
  - `vps-deploy-web.sh` 에 두 파일 배포·내용검증·HTTP 확인 추가
- [x] H4(P4). 앱 복귀 처리
  - `startTossPayment()` / `onNativePayReturn()` 추가
  - **native.js 라우팅 버그 수정** — OAuth 실패와 결제 실패가 둘 다 `code=` 를 달고 와서
    파라미터로 갈라내던 기존 코드는 구글 PKCE 로그인을 결제 처리로 보냈다. 호스트(`auth`/`pay`)로 갈랐다
  - verify: 5개 URL 케이스(결제 성공·결제 실패·PKCE 코드·토큰·OAuth 거부) 전부 올바른 쪽으로 라우팅
- [x] H5(P5). 결제 시트에 `🔒 카드로 미리 결제` 추가. `TOSS_ENABLED=false` 로 **지금은 숨김**
  - 쿠폰은 결제 전에 `discount_vnd` 로 예약에 먼저 반영한다. 서버가 `amount_vnd - discount_vnd` 로 다시 계산하므로 화면 금액과 일치한다
- [ ] H6(P6). 토스 가입 → 테스트 키 입력 → `TOSS_ENABLED=true` → 전 구간 검증 → 라이브 키

> 결제 시트의 기존 `카드`·`QR`·`은행 이체` 는 **PG 연결 없이 `is_paid=true` 로 찍는 자리표시자**다.
> 이번 작업에서 건드리지 않았다. 토스가 살아나면 이것들을 어떻게 할지 따로 정해야 한다.

### 주의
- Zalo 는 이번 범위에서 제외 (계정 본인인증 후 별도 진행)
- `APP_SCHEME` (index.html) 과 codemagic.yaml 의 `CFBundleURLSchemes` 는 **항상 같은 값**이어야 한다
