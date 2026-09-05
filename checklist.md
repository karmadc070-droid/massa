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

- [~] A2-9. 메일 템플릿 한국어화 — **사장님이 넘기기로 결정** (2026-09-05). 기본 영문 그대로 둔다
- [~] A2-10. Resend API 키 회전 — **사장님이 넘기기로 결정** (2026-09-05)
  - 남는 위험: 그 키로 `moahagwon.com` 발신 메일을 임의로 보낼 수 있다. 나중에 마음 바뀌면 Resend 콘솔에서 새 키 발급 후 `vps-setup-smtp.sh` 재실행

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
- [ ] C2. **안드로이드 TWA 가 낡은 Vercel 빌드를 본다 — C4 의 선행 조건** (2026-09-05 확인)
  - `android-package/massa.aab`(2026-08-14 업로드) 안의 시작 URL = `https://massa-seven.vercel.app/?src=pwa`
  - 그 Vercel 배포본(200 / 333KB)을 실제로 받아보니 **마이그레이션 이전 버전**이다
    | 표식 | Vercel(안드로이드가 보는 것) | massa.moahagwon.com(최신) |
    |---|---|---|
    | `nativeapp` (1.0.4 전체화면) | 0 | 4 |
    | `TOSS_ENABLED` | 0 | 2 |
    | `delete-account` | 0 | 있음 |
    | API 주소 | `massa.141-164-46-88.sslip.io` (구 주소) | `massa.moahagwon.com` |
    | `관리자` 문자열 | 45 | 27 |
  - `assetlinks.json` 은 **Vercel 도메인에만** 있다 (moahagwon·massaviet 는 404)
  - 즉 안드로이드 테스터 12명은 지금 **구버전 앱**을 쓰고 있다. 프로덕션 신청 전에 정리해야 한다
  - **①로 해결(2026-09-05).** Vercel 수동 배포 API 를 커밋 `a8b0cb8` 로 호출 → `READY`, `massa-seven.vercel.app` 별칭 연결
    - verify: 292,713 bytes 로 `massa.moahagwon.com` 과 **동일 크기**, `nativeapp` 4 / `TOSS_ENABLED` 2 / `CANCEL_RULES` 12
    - API 주소가 `massa.moahagwon.com` 으로 교체됨 (구 `sslip.io` 0건)
    - `delete-account`·`privacy`·`terms`·`pay-start`·`pay-return` 전부 200, `assetlinks.json` 200 (`app.massa.hanoi` 유지 → TWA 검증 안 깨짐)
  - Vercel 은 git 자동배포가 없다. 배포 트리거는 `PLAY_STORE_진행상황.md` §4 의 `/api/v13/deployments` 스니펫

### C2-2. TWA 를 자체 도메인으로 옮기는 건 (검토만, 2026-09-05)
사용자 요청 — "도메인이 있으니 Vercel 말고 여기로 다 옮기자". 확인 결과 **가능하지만 지금은 아니다.**
- **iOS 는 무관하다.** `capacitor.config.json` 이 `webDir: "www"` — 원격 URL 이 아니라 **번들 자산**을 쓴다
- 안드로이드만 해당. 시작 URL 은 aab 안에 박혀 있어 **bubblewrap 재빌드 + versionCode 증가 + Play 재업로드**가 필요하다
- 새 호스트에 `assetlinks.json`(지문 2개) 를 먼저 올려야 한다. 안 그러면 주소창이 뜨는 반쪽 TWA 가 된다
- 후보는 `app.massaviet.com`. 현재 앱 주소 `massa.moahagwon.com` 은 **학원 브랜드가 드러난다** — 도메인을 분리한 이유와 어긋나므로 옮길 값어치가 있다
- ⚠️ **API 호스트는 옮기면 안 된다.** 이미 출시된 iOS 1.0~1.0.3 에 `massa.moahagwon.com` 이 박혀 있어 끊으면 기존 사용자가 죽는다. 옮기는 건 **웹 호스트만**
- ⚠️ 프로덕션 신청(9/7)까지 2일이다. 재업로드가 14일 요건 계산에 영향을 주는지 확인되지 않았다.
  **콘텐츠 결함은 위에서 이미 해소됐으므로**, 신청을 먼저 하고 도메인 이전은 다음 릴리스로 미루는 편이 안전하다
- [x] C3. VPS DB 논리 백업 — **이미 돌고 있다** (2026-09-05 확인)
  - `crontab: 10 3 * * * /root/pg_backup.sh`, massa-db 포함 4개 DB 를 매일 03:10 덤프
  - `/root/backups` 에 10일치 보관, 디스크 26% 사용으로 여유 있음
  - ⚠️ 같은 서버에만 있다. 서버가 통째로 죽으면 같이 죽는다 — 외부 보관은 별도 과제
- [ ] C4. Google Play 프로덕션 신청 — 콘솔 확인(2026-09-05): **"현재 12일 동안 참여를 선택한 테스터 12명"**, 14일 요건까지 2일 남음
  - 신청 버튼은 비활성. 대략 **2026-09-07** 이후 활성화된다. 신청 시 비공개 테스트에 관한 서술형 질문에 답해야 한다
  - 승인 전까지 Play 스토어 URL 은 일반 방문자에게 404 다 (개발자 계정으로는 보인다 — 착각하기 쉽다)
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
- [x] I4. Codemagic **build 17 성공** — 16단계 전부 통과. TestFlight `1.0.3 / build 17 / 제출 준비 완료`
- [x] I5. App Store Connect **1.0.3 버전 생성** → 변경사항 작성 → build 17 첨부 → 저장 완료
  - `심사에 추가` 버튼 활성 상태. **제출은 아직 누르지 않았다**
- [x] I6. 실기기(TestFlight)에서 버튼 3개 노출 확인 — 사장님 확인
- [x] I7. **토큰 교환까지 검증 완료** — 실계정 없이 확인했다 → `scripts/vps-verify-social-secrets.sh`
  - 원리: 토큰 엔드포인트에 일부러 틀린 code 를 보낸다.
    시크릿이 틀리면 `invalid_client`, 맞으면 `invalid_grant` 가 온다
  - 결과: 구글·카카오(KOE320)·애플 **셋 다 `invalid_grant`** = 클라이언트 인증 통과
  - 이걸로 **애플 JWT 와 .p8/Key ID 짝**까지 확인됐다. 서버에서 생성한 부분이라 가장 불확실했던 곳이다
  - 시크릿 값은 VPS 안에서만 읽어 화면에 출력하지 않는다
- [x] I8. **1.0.3 심사 통과·출시 완료** (2026-09-05)

## K. 1.0.4 — 화면이 꽉 차지 않던 문제 (2026-09-05)

**증상**: 앱을 켜면 화면에 꽉 차지 않고 좌우로 움직인다.

**원인**: `.phone` 은 데스크톱에서 볼 때 쓰는 **폰 목업 프레임**(테두리 10px, 둥근 모서리, 가짜 상태바)이다.
이걸 벗기는 규칙이 `@media (max-width: 767px)` 안에만 있어서 **세로 아이폰만** 적용됐다.

| 상황 | 수정 전 | 수정 후 |
|---|---|---|
| 아이폰 세로 375×812 | 375×812 정상 | 그대로 |
| **아이폰 가로 844×390** | 카드 315×560, 좌우 여백 257px, **높이가 화면보다 큼** | 844×390, 여백 0 |
| **아이패드 820×1180** | 카드 518×920, 좌우 여백 151px, 가짜 상태바 노출 | 820×1180, 여백 0 |

- [x] K1. `body.nativeapp` 클래스로 **화면 크기·방향과 무관하게** 목업을 벗기도록 수정
  - `IS_NATIVE_APP` 이 true 일 때만 클래스가 붙는다 → 웹은 그대로 (회귀 확인함)
  - 미디어쿼리는 손대지 않았다. 웹의 좁은 화면 동작은 기존과 동일
- [x] K2. 세 크기 전부 검증 — 여백 0, 가로 스크롤 없음, 뷰포트보다 넓은 요소 0개
- [x] K3. Codemagic **build 18 성공** → 1.0.4 생성·첨부 → **심사 제출 완료** (2026-09-05, 심사 대기 중)

> **왜 여태 안 보였나.** 세로 아이폰만 테스트했다. 가로로 돌리거나 아이패드로 열면 바로 드러나는 문제였다.
> 반응형은 **한 크기가 아니라 경계값**(767/768)을 넘겨보며 확인해야 한다.

## J. 비로그인 접근 점검 (2026-09-04)

"로그인 없이 다 클릭된다"는 지적을 받고 확인했다. **의도된 설계이고 문제 없다.**

- 둘러보기를 막지 않는 건 애플이 권하는 방향이다. 로그인 뒤에 콘텐츠를 숨기면 **5.1.1(v) 리젝** 사유가 된다
- 세션 없는 브라우저로 실제 호출 — 예약확정·결제·채팅·리뷰·신고·쿠폰·찜·예약내역 **전부 로그인창이 뜬다** (코드 내 가드 28곳)
- **DB 직접 검증** (앱을 거치지 않고 anon 키로 REST 호출)
  - 읽기: 예약·프로필·메시지·결제·서류·신고 전부 **빈 결과**. 남의 데이터가 새지 않는다
  - 쓰기: 6개 테이블 전부 **42501 (RLS 위반)** 로 차단
  - 전 테이블 RLS 켜짐, 정책이 `auth.uid()` 로 소유자 검사

> 남겨둔 것: `cancelBooking` 만 SESSION 검사가 없다. 예약 목록에서만 닿을 수 있고
> 비로그인은 목록이 비어 있어 도달 불가이며, 취소 시도 자체도 RLS 가 막는다. 실질 위험 없음.

> ⚠️ **테스트하다 헛짚은 것**: `toggleFav` 로 호출해 "가드 없음"으로 잘못 판단했다.
> 실제 함수명은 `toggleFavorite` 이고 가드가 있다. **함수명을 먼저 확인하고 호출할 것.**

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

## L. massaviet.com 소개 사이트 + 검색 등록 (2026-09-05)

**왜 분리했나.** 모아학원은 학부모·아이 대상 학원 플랫폼이다. 마사지 서비스가 같은 도메인 아래 있으면
검색이나 주소로 연결이 드러났을 때 학부모 신뢰에 직접 영향을 준다. 애드센스 이전에 이 이유만으로 분리할 값어치가 있다.

- [x] L1. 도메인 `massaviet.com` 구매 (Cloudflare Registrar, 2027-09-05 만료, auto-renew ON)
  - 브랜드가 앞에 오는 `massaviet` 를 골랐다. 앱 이름이 massa 라 자동완성과 각인에 유리하다
- [x] L2. DNS 4개 레코드 — apex·www 각각 A(141.164.46.88) / AAAA. **DNS only**(Caddy 가 인증서를 직접 발급)
  - ⚠️ Cloudflare DNS UI 가 좌표·React 양쪽으로 계속 어긋났다. **대시보드 세션으로 `/api/v4` 를 직접 호출**해 해결
- [x] L3. 소개 사이트 10개 페이지 — 홈·서비스·이용안내·안전검증·FAQ·파트너·회사소개·문의·약관·개인정보
  - 공용 `style.css`, 페이지마다 title·description·canonical·OG, 홈에 LocalBusiness / FAQ 에 FAQPage 구조화 데이터
  - verify: 10개 전부 메타 6항목 통과, div 균형, 내부 링크 깨짐 0
- [x] L4. VPS 배포 — `scripts/vps-deploy-massaviet.sh`, Caddy + Let's Encrypt
  - verify: 12개 경로 전부 200, `www` → apex **301**
- [x] L5. `robots.txt`(사이트맵 선언) · `sitemap.xml`(10 URL)
- [x] L6. **구글 서치콘솔** — 도메인 속성으로 등록, TXT 를 Cloudflare API 로 넣어 **"소유권이 자동으로 확인됨"**
- [x] L7. **빙 웹마스터** — `massaviet.com` 추가, `msvalidate.01` 메타 태그를 홈에 심어 확인 완료
- [x] L8. **사이트맵 제출** — 구글 "사이트맵이 제출됨", 빙 `Success / 11 URL 발견`
  - 도메인 속성은 `sitemap.xml` 만 넣으면 "사이트맵 주소가 잘못됨"이 뜬다. **전체 URL**을 넣어야 한다
  - 입력이 안 먹던 이유는 필드가 아니라 **위에 떠 있던 홍보 툴팁이 클릭을 가로챈** 것이었다. 툴팁을 닫으니 바로 됐다
- [ ] L9. 네이버 서치어드바이저 등록 — **자동화 불가**. 브라우저 양쪽 모두 `searchadvisor.naver.com` 접속이 차단된다
  - 사용자가 직접 사이트 추가 후 **메타 태그 content 값만** 넘겨주면 배포·확인은 내가 한다 (빙과 같은 방식)
- [ ] L10. 다음(카카오) 검색 등록 — **자동화 실패**. `_jsSubmit` 이 어떤 URL 형식도 "URL을 정확히 기입하여 주십시요."로 반려
  - `https://`, `http://`, 스킴 없음, `www` 포함 6가지 전부 실패. 검증 함수 소스는 확장 필터에 막혀 읽지 못했다
  - 어차피 2단계가 **개인정보수집·소유권 동의**라 사용자 승인이 필요하고, 마사지 업종은 **제출 서류**를 요구할 수 있다
- [ ] L11. 애드센스 신청 — **콘텐츠가 더 쌓인 뒤에**

### L12. 사이트 ↔ 앱 연결 (2026-09-05)
- [x] `site/download.html` 신설 — App Store 버튼(실링크) + Google Play(`.store.off`, 링크 없음)
- [x] 8개 페이지 헤더 nav · 푸터에 "앱 다운로드" 추가, 홈 히어로 1순위 CTA 를 다운로드로 교체
- [x] 홈에 스토어 버튼 섹션, `LocalBusiness` 구조화 데이터에 `sameAs` 로 App Store URL
- [x] `sitemap.xml` 11 URL 로, 배포 스크립트 검증 목록에 `download.html` 추가
- verify: 13개 경로 전부 200, 홈 applelink=2 / playlink=0, 8개 페이지 nav 전파 확인
- **Play 링크를 일부러 걸지 않았다.** 프로덕션 트랙이 아직 `12일 / 14일 필요`라 공개 URL 이 없다.
  개발자 계정으로는 스토어 페이지가 보이지만 일반 방문자에겐 404 다. 죽은 다운로드 버튼은 예전에 겪은 4.0 리젝과 같은 결함이다
- 프로덕션 승인 뒤 할 일: `site/download.html` · `site/index.html` 의 `.store.off` 두 곳을 실링크로 교체

> **취소 규정 불일치를 잡았다.** 소개 사이트 초안에 "2회 경고·3회 제한"으로 썼는데,
> 앱의 실제 값(`CANCEL_RULES`)과 약관은 **3회 경고·5회 누적 7일 제한**이었다.
> 추측으로 쓴 숫자였고, 실제 상수를 읽어 guide·faq 양쪽을 고쳤다.

> **애드센스 관련 솔직한 판단.** 지금 10페이지는 "회사 소개형"이라 애드센스가 저품질로 볼 여지가 있다.
> 하노이 마사지·홈뷰티 관련 실질 정보 글이 몇 편 더 쌓인 뒤 신청하는 편이 승인 확률이 높다.
> 또한 massa 는 수수료 10% 로 버는 사업이라 광고 수익 자체는 크지 않다 — 기대치를 낮게 잡는 편이 낫다.

## M. massa bot 정비 (2026-09-05)

**전제 정정.** "massa 에 챗봇을 만들자"로 시작했으나 **봇은 이미 있다**. `index.html` 3038~3168행,
FAB `openBot()` + 규칙 FAQ 15개 + 자연어 검색(`parseSearch` 7종 조건 → `CACHE.providers` 필터).
내가 `botReply` 로만 검색해 0건을 보고 "없다"고 했던 것이 오판이었다. 실제 함수명은 `botAnswer`·`openBot` 이다.
따라서 이 작업은 신규 구축이 아니라 **기존 봇의 결함 정비**다. LLM 은 붙이지 않기로 했다(사장님 선택).

### 발견한 결함
- **M-a 봇이 한국어로만 말한다.** 답변 14개 + 퀵리플라이 6개 = **20개 전부 `DICT` 미등록**.
  앱의 나머지 문구는 5개 언어가 다 있는데 봇만 빠졌다. 하노이 서비스라 베트남어 사용자가 가장 큰데 치명적이다.
- **M-b 키워드 매칭도 한국어 전용.** `has('예약','어떻게'...)` 라서 베트남어·영어로 물으면 **어떤 규칙에도 안 걸리고**
  기본 문구로 떨어진다. 답변만 번역해서는 해결되지 않는다.
- **M-c 퀵리플라이를 번역하면 검색이 깨진다.** 칩 텍스트가 그대로 `respond()` 로 들어가는데
  `parseSearch` 는 한국어 정규식('만','커플','여성전용')이다. 번역된 칩을 누르면 파싱이 실패한다.
  → **표시는 번역문, 전달은 한국어 원문**으로 분리해야 한다.
- **M-d 문의 경로가 끊겨 있다.** 봇은 "계정 → 회사 소개의 연락처"를 안내하는데
  회사 소개는 `alert()` 한 줄(3295행)이고 연락처가 없다. 사이트가 안내하는 `support@massaviet.com` 은
  **MX 레코드가 없어 반송**된다. 사용자가 문의할 방법이 실제로 없다.
- **M-e 가격이 하드코딩.** "아로마 90분 850,000₫" 을 봇이 단언한다(3044행). DB 값이 아니라 상수다.
- **M-f 취소 규정이 뭉뚱그려져 있다.** "다음 예약이 제한될 수 있습니다" — 실제는 `CANCEL_RULES`
  3회 경고 / 5회 누적 7일 제한 / 30일 창. 사이트·약관과 표현을 맞춰야 한다.

### 작업
- [x] M1. FAQ 를 `BOT_FAQ` 배열로 재구성 — 규칙 13개 / 키워드 171개, 5개 언어 전부 검사
  - **순서가 우선순위다.** 좁은 의도(취소·쿠폰·가격·내 예약)를 넓은 의도(예약 방법)보다 앞에 뒀다
  - verify: 25건 시뮬레이션 전부 통과, 여러 규칙에 중복된 키워드 0
- [x] M2. 퀵리플라이 — 표시 `T(ko)` / 전달 `ko` 분리
  - verify: 칩 6개 전부 한국어 원문으로 `parseSearch` 통과 (커플·한국인 인기·발마사지·10만원 이하)
- [x] M3. 봇 문구 35개를 `scripts/i18n-add.py` 로 DICT 등록 → verify: 미등록 0건
- [x] M4. 가격을 `CACHE.services` 최저가로 계산 (하드코딩 850,000₫ 제거)
- [x] M5. 취소 답변을 `CANCEL_RULES` 에서 생성 → 3회/5회/7일/30일
- [x] M6. 문의 경로 복구 — 회사 소개 alert 에 `SUPPORT_EMAIL`·massaviet.com 추가, 봇도 실제 주소 안내
- [x] M7. Cloudflare Email Routing 개통 — `support@massaviet.com` → 개인 메일 전달
  - verify: 외부 DNS(1.1.1.1)에서 MX 3개(`route1~3.mx.cloudflare.net`) + `v=spf1 include:_spf.mx.cloudflare.net` 확인
  - 웹 A 레코드(141.164.46.88)는 그대로 — 사이트에 영향 없음
- [x] M8. 배포 후 라이브에서 5개 언어 확인 — UI·인사·칩·placeholder 전부 해당 언어로 렌더

> **조각 이어붙이기로 만든 문장이 깨졌다.** 숫자가 들어가는 답변을 `T('예약') + h + T('시간 전까지…')`
> 식으로 조립했더니 베트남어에서 **"5lần thì 7bị hạn chế đặt lịch trong ngày"** 처럼 어순이 무너졌다.
> 언어마다 숫자 위치가 다른데 한국어 어순을 고정해 버린 탓이다.
> **문장 전체를 사전에 넣고 `{h}`·`{w}` 자리표시자만 치환**하도록 바꿔 해결했다(`botFill`).
> 조각 키 10개는 다른 문구를 오역할 소지가 있어 DICT 에서 삭제했다.
> 코드를 눈으로 봤을 때는 멀쩡해 보였고, **실제로 돌려보고서야 드러났다.**

> **번역 품질 주의.** 5개 언어 번역은 내가 작성한 것이다. 특히 베트남어는 주 사용자층 언어이므로
> 원어민이 한 번 훑어보는 편이 좋다. 문장 구조는 검증됐지만 어감까지 보장하지는 못한다.

## N. 전체 점검 (2026-09-05)

사장님 요청으로 인프라·앱·DB·메일을 실제로 돌려 확인했다.

### 정상 확인
- 웹 엔드포인트 **16개 전부 200** (앱·admin·massaviet·Vercel·법적 페이지·결제 릴레이·assetlinks)
- 컨테이너 **12개 전부 healthy**, 디스크 26%, 인증서 전부 11~12월 만료(여유)
- 백업 **4개 DB 매일 03:10**, massa-db 포함 33개 보관
- 소셜 로그인 **apple·google·kakao 전부 `true`**
- 익명 RLS — 공개 카탈로그만 읽히고(providers·services·stores·reviews),
  개인 데이터(bookings·profiles·messages)는 `[]`, 쓰기는 4개 테이블 전부 **42501**
- 취소 규정 **4개 면 일치** (앱 상수·앱 봇·사이트 guide/faq·약관 = 3회/5회/7일/30일)
- 가격 하드코딩 **0건**
- Cloudflare Email Routing **enabled / status=ready / DNS동기화됨**, support 규칙 활성

### 찾아서 고친 것

- [x] **N1. 로그인 오버레이가 통째로 미번역이었다** — 가장 큰 결함
  - `openAuth()` 의 15개 문구(제목·안내·입력 placeholder·버튼·소셜 3종·오류 문구)가 전부 `DICT` 에 없었다
  - **예약하려는 비한국어 사용자가 처음 만나는 화면**인데 한국어로 떴다. 하노이 = 베트남어가 주 사용자층이다
  - 봇만 고쳤을 때 "다국어 됐다"고 넘어갈 뻔했다. 화면을 실제로 훑어보고서야 드러났다
  - verify: 라이브에서 베트남어로 전환 후 확인 — 제목·부제·placeholder·버튼·소셜 전부 베트남어

- [x] **N2. 안드로이드 TWA 에 1.0.4 전체화면 수정이 적용되지 않고 있었다**
  - `body.nativeapp` 은 `IS_NATIVE_APP`(Capacitor)일 때만 붙는다. **안드로이드는 TWA 라 false** 다
  - 남은 건 `@media (max-width: 767px)` 뿐이라 **가로 모드(폭 767 초과)·태블릿에서 폰 목업 테두리와
    가짜 상태바가 그대로 노출**된다. iOS 1.0.4 에서 고친 것과 똑같은 증상이 안드로이드에만 남아 있었다
  - 수정: `@media (display-mode: standalone/fullscreen/minimal-ui)` 추가. TWA·PWA 는 standalone 으로 뜨므로
    플래그 없이 잡힌다. 일반 브라우저 탭은 `browser` 라 영향 없음
  - verify: CSSOM 에 규칙 3개 파싱됨, 브라우저 탭에서는 `현재매치=false` 로 목업 유지(회귀 없음)
  - VPS·Vercel 양쪽 재배포 완료 → 안드로이드에 반영됨

### 확인 못 한 것 / 남은 것
- [ ] N3. `support@massaviet.com` **실제 수신 테스트** — VPS 25번 포트가 막혀 서버에서 발송 불가.
  사장님이 아무 계정에서 한 통 보내보시면 확정된다
- [ ] N4. iOS 1.0.4 심사 상태 — App Store Connect 세션이 만료돼 확인 못 했다
- `zalo-login` 이 500 을 낸다 — 버그가 아니라 `ZALO_APP_ID 미설정`(C5 미완료). 앱 UI 에서 도달 불가
- 앱 전 화면 다국어 스윕은 완주하지 못했다. 사장님 크롬의 1688 번역 확장이 DOM 을 계속 주입해
  MutationObserver(60ms 마다 `translateTree(body)`)와 겹치면서 렌더러가 멈췄다. 확장 없는 환경에서 다시 볼 것

## O. massaviet.com 전면 재설계 (2026-09-06)

사장님 요청 — awwwards 를 참고해 깔끔하고 엘레강스한 사이트로 다시 만들고 앱을 연동한다.
정한 방향: **따뜻한 에디토리얼 / 한국어·영어·베트남어 / 10페이지 전체 재설계**.

### 구조를 바꿨다
10페이지 × 3언어 = 33개를 손으로 관리할 수 없어 **생성기 방식**으로 갔다.
- `site-src/content_{ko,en,vi}.py` — 페이지를 **블록 데이터**로 기술 (hero·section·grid·pcards·steps·table·faq·pull·note·stores)
- `site-src/build.py` — 블록을 HTML 로 찍고 hreflang·sitemap·robots·FAQ 구조화 데이터를 자동 생성
- `site-src/style.css` — 디자인 시스템 한 곳
- `site/` 는 **자동 생성물**이다. 직접 고치지 말고 content 를 고친 뒤 `python3 site-src/build.py` 를 돌린다
- ko 는 루트, 영어는 `/en/`, 베트남어는 `/vi/`. 33개 URL 이 서로를 hreflang 으로 가리킨다

### 이미지
사이트가 이미지를 **하나도 안 쓰고 있었다.** 그게 싸구려로 보이던 가장 큰 이유다.
- `masaage1.png` 를 히어로로 썼다 — 유일하게 문구가 안 박힌 깨끗한 사진이다
- `banner2·3` 은 왼쪽에 한국어가 박혀 있어 **오른쪽만 잘라** 홈뷰티·스파 카드로 썼다
- 전부 WebP 로 변환, 5장 합쳐 **184KB**
- ⚠️ `11~99.jpg`(아오자이 인물사진 9장)는 **쓰지 않았다.** 350×450 이라 히어로로 못 쓰고,
  출처 불명 실존 인물이라 초상권 문제가 있으며, 무엇보다 마사지 서비스 홈에 젊은 여성 얼굴을
  격자로 깔면 massa 가 쌓아온 포지셔닝과 정면으로 어긋난다

### 만들면서 잡은 것
- [x] **한글 제목이 엉뚱하게 끊겼다** — `max-width: 12ch` 가 원인. `ch` 는 라틴 폰트의 '0' 폭 기준이라
  82px 한글에 469px 밖에 안 준다. max-width 를 없애고 줄바꿈은 콘텐츠의 `<br>` 로 정하도록 바꿨다.
  `word-break: keep-all` 도 넣었다 — 없으면 한글이 단어 중간에서 끊긴다
- [x] **한글에 세리프가 안 먹었다** — Cormorant 에는 한글 글리프가 없어 시스템 고딕으로 떨어지고
  라틴/한글 인상이 따로 놀았다. `Noto Serif KR` 을 추가했다
- [x] **"3단계 검증"의 3 이 아래첨자처럼 보였다** — Cormorant 가 올드스타일 숫자를 기본으로 쓴다.
  제목에만 `font-variant-numeric: lining-nums` 를 걸었다
- [x] **CSS 수정이 반영되지 않았다** — Caddy 가 10분 캐시한다. 내용 해시를 `style.css?v=…` 로 붙여 해결
- [x] **배포 스크립트가 `img/` 를 못 옮겼다** — `cp` 가 디렉터리를 건너뛰었다. `cp -R` 로 바꾸고
  배포 전 대상 폴더를 비우도록 했다(배포본 = 저장소 상태)
- [x] **모바일에서 언어 전환이 사라졌다** — `nav.main a:not(.navcta)` 가 언어 링크까지 숨겼다.
  베트남 사용자 대부분이 모바일인데 언어를 못 바꾸는 상태였다. 직계 자식만 숨기도록 고쳤다

### 앱 연동
- 헤더 CTA·홈 스토어 섹션·전용 다운로드 페이지, 3개 언어 전부
- 모바일에서만 뜨는 **설치 유도 띠**(한 번 닫으면 localStorage 로 기억)
- Play 는 여전히 링크를 걸지 않는다(`PLAY_LIVE=False`). 프로덕션 승인되면 `build.py` 의 그 값만 True 로 바꾸고 다시 빌드

### 곁다리로 잡은 사실 오류
개인정보처리방침이 처리 위탁을 **"Supabase Inc."** 로 적고 있었다. 자체 호스팅으로 옮긴 뒤라 사실과 다르다.
서버 위치를 확인하니 Vultr(The Constant Company) **서울 리전**이라 지역 표기는 맞았다.
수탁자를 실제 사업자로 정정하고 Resend·Cloudflare 도 추가했다(3개 언어 모두, 버전 1.1).

### 검증
- 33개 페이지 전부 200, 깨진 링크 0, 필수 메타 6항목 전부 통과
- hreflang 상호 참조 3언어 × 4개(ko·en·vi·x-default) 확인
- FAQ 구조화 데이터 언어당 18문항 자동 생성
- sitemap 33 URL / 99 alternate
- 390px 에서 가로 스크롤 없음, 넘치는 요소 0, 언어 전환·CTA·설치 띠 정상

### 남은 것
- [ ] O1. **베트남어 원어민 검수** — 번역은 내가 썼다. 하노이 현지 고객과 파트너 모집에 쓰이는 언어이므로
  실제 홍보 전에 한 번 훑어보게 하는 편이 좋다. 문장 구조는 맞지만 어감까지 보장하지 못한다
- [ ] O2. 구글 서치콘솔·빙에 사이트맵 재크롤 확인 (URL 은 그대로라 자동으로 잡히지만 며칠 걸린다)
- [ ] O3. 사진이 3장뿐이라 페이지마다 같은 이미지가 반복된다. 실제 서비스 사진이 생기면 교체할 것

## P. 수수료 입금 관리 (2026-09-06)

**해결한 문제.** 현금 거래가 대부분이라 마사지사가 회사 계좌로 수수료를 이체하는데,
**동명이인이 있어 통장만 봐서는 누가 냈는지 알 수 없다.**

### 방식
제공자마다 `MS####` 고유 코드를 발급하고, 이체 메모(또는 입금자명)에 적게 한다.
관리자 화면에 코드가 함께 뜨므로 통장과 1:1 대조된다.

### 스키마 — `scripts/settlement_schema.sql` (저장소에 DDL 을 남겼다)
기존 `settlement`·`settlement_cycle` 은 **DDL 이 저장소에 없고 VPS 에만 있었다.** 새로 만드는 것은 파일로 남긴다.
- `providers.deposit_code` — `MS` + 4자리, unique. 27명 전원 자동 발급
- `provider_deposit` — 입금 신고·확인. `kind`(commission|prepay), `status`(reported|confirmed|rejected), `memo`, `proof_url`
- `provider_credit` / `provider_credit_tx` — 선입금 잔고와 증감 내역 (페이백용, 지금은 안 씀)
- `owns_provider(uuid)` — 본인 소유 판정 (프리랜서 `profile_id`, 샵 `owner_id` 양쪽)
- `confirm_deposit(uuid)` RPC — 관리자만. 수수료면 사이클을 `paid` 로, 선입금이면 보너스까지 잔고에 적립
- RLS — 제공자는 자기 것만 조회·신고, 확인은 관리자만

### 화면
- **관리자(정산 관리)** — 이름 옆에 코드 배지, 마사지사가 올린 신고를 노란 박스로 띄우고
  `통장 확인함·승인` / `확인 안 됨`(사유 입력 → 알림 발송) 버튼
- **마사지사(내 입금 현황)** — 자기 코드를 크게 보여주고 `입금했습니다` 로 금액·메모를 신고, 처리 상태 표시
- 하드코딩 `10%` 라벨을 `FEE_RATE` 로, `3일` 을 `DUE_DAYS` 로 바꿨다 (설정과 화면이 어긋나던 것)
- `admin.html` 에 이스케이프 헬퍼가 없어 `esc()` 를 만들었다 — 이체 메모는 사용자 입력이다

### 선입금(페이백) — 스키마만, 기능은 끔
`app_settings.prepay` 에 `enabled:false` 와 3구간을 넣어 뒀다. **금액은 임시값이다.**
- 200만₫ 이상 → 보너스 10% / 500만₫ 이상 → 15% / 1,000만₫ 이상 → 20%
- 90분 아로마 850,000₫ 기준 건당 수수료가 85,000₫ 이라 월 20건이면 1.7M₫ 정도. 그 기준으로 잡은 값이다
- 실제 운영 전에 사장님이 금액을 정해야 한다

### 검증 — DB 에서 전 과정을 돌렸다
| 항목 | 결과 |
|---|---|
| 수수료 신고 → 승인 | `confirmed`, `settlement.status = paid` 로 전이 |
| 선입금 500만₫ + 보너스 75만₫ | 잔고 **5,750,000₫**, 내역 `prepay`/`bonus` 2건 |
| 같은 건 두 번 승인 | 잔고 그대로 (멱등) |
| 비관리자 승인 시도 | `관리자만 확인할 수 있습니다` 로 차단 |
| 테스트 데이터 | 전부 삭제, 남은 행 0 |

### 관리자 메일
- [x] `karmadc070@gmail.com` — admin 권한 있음 (2026-08-29 가입)
- [ ] **P1. `moahagwon@gmail.com` 은 아직 massa 계정이 없다.** 앱이나 admin 콘솔에서 그 메일로
  가입하시면 admin 권한을 부여하겠다
- [ ] **P2. Cloudflare 수신 주소 확인 필요.** `moahagwon@gmail.com` 을 수신 주소로 등록했고
  확인 메일이 갔다. 그 메일함에서 링크를 눌러야 `확인 대기` → `확인됨` 이 된다
  - ⚠️ Cloudflare Email Routing 은 **규칙당 액션 1개, 액션당 주소 1개**만 허용한다.
    한 주소를 두 곳으로 보내려면 같은 matcher 로 규칙을 하나 더 만들어야 하는데,
    수신 주소가 확인되기 전에는 생성 자체가 거부된다. 확인 후 다시 시도할 것
- [ ] **P3. 관리자 알림 메일 경로가 아예 없다.** massa 에는 관리자에게 메일을 보내는 코드가 없다
  (Resend 는 Supabase Auth 메일 전용). 입금 신고·기한 초과를 메일로 받으려면
  Edge Function 을 새로 만들어야 한다. 지금은 앱 내 `notifications` 알림만 간다
