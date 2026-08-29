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
