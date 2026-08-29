# massa 작업 체크리스트

## A. API 도메인 교체 (sslip.io → moahagwon.com 서브도메인)

목표: 앱이 임시 도메인 대신 정식 도메인을 바라보게 하고, IPv6 미지원 문제를 없앤다.

- [ ] A1. Cloudflare에 `api.moahagwon.com` 레코드 추가 → verify: dig A/AAAA 응답 확인
  - A: `141.164.46.88`, AAAA: `2401:c080:1c02:7e6:5400:6ff:fe98:627f`
  - **프록시 끄기(DNS only)** — Supabase Realtime WebSocket·Storage 업로드가 프록시 제약을 받지 않도록
- [ ] A2. VPS Caddy에 `api.moahagwon.com` → `localhost:8002` 블록 추가 → verify: `curl -I https://api.moahagwon.com/rest/v1/` 200/401
- [ ] A3. IPv6 접근 확인 → verify: `curl -6 -I https://api.moahagwon.com/auth/v1/settings`
- [ ] A4. index.html의 SUPABASE_URL 교체 → verify: 브라우저에서 로그인·목록 로드 성공
- [ ] A5. Storage 파일 URL 치환 (DB 안 21곳, 이전에 sslip.io로 바꾼 것) → verify: 제공자 사진 표시
- [ ] A6. 심사 정보(App Review Notes)의 서버 URL 갱신
- [ ] A7. 빌드·제출 → verify: TestFlight 실기기에서 로그인·예약 동작

## B. 관리자·파트너 기능 웹 이전 (23개 화면)

목표: 앱은 고객 전용으로 남기고, 운영 기능은 `admin.moahagwon.com`에서 관리자 로그인 후 사용한다.

### B0. 준비
- [ ] B0-1. `admin.html` 스캐폴드 (Supabase 클라이언트·로그인·역할 검사) → verify: 관리자 아닌 계정은 접근 거부
- [ ] B0-2. 배포 경로 결정 (Vercel 별도 프로젝트 vs VPS Caddy 정적 서빙)

### B1. 관리자 화면 13개 이전
adminApps(심사) · adminStats · adminReports · adminMembers · adminSettlement · adminAds · adminFraud · adminBookings · adminProviders · adminFee · adminCoupons · adminSales · adminCountry
- [ ] B1-1. 화면 마크업·핸들러를 admin.html로 이동 → verify: 각 화면 데이터 로드 확인
- [ ] B1-2. 앱(index.html)에서 해당 화면·메뉴 행 제거 → verify: 앱 문법 검사 + 고객 플로우 정상

### B2. 파트너 화면 10개 이전
partnerBookings · partnerRevenue · partnerSchedule · partnerEvents · partnerStaff · partnerSettle · partnerChat · partnerGps · partnerAi · partnerAiBiz
- [ ] B2-1. 화면 이전 → verify: 파트너 계정으로 로그인해 데이터 확인
- [ ] B2-2. 앱에서 제거 → verify: 문법 검사 + 고객 플로우 정상
- [ ] B2-3. `isPartner` 판정 로직 정리 (앱에 남을 필요가 없어짐)

### B3. 마무리
- [ ] B3-1. demo 계정 파트너 권한 정리 여부 결정 (심사용으로 필요한지)
- [ ] B3-2. 앱 빌드·제출 → verify: 실기기에서 계정 화면에 운영 메뉴가 없음
- [ ] B3-3. 인계서(IOS_진행상황.md) 갱신

## C. 기타 남은 일
- [ ] C1. build 12 실기기 로그인 확인 (2.1a 근본 원인 확정)
- [ ] C2. Vercel 웹사이트 최신 배포 (현재 구버전, git 미연동)
- [ ] C3. VPS DB 논리 백업(pg_dump 정기) 설정 — 서버 스냅샷 백업은 Vultr에서 Enabled 확인됨
- [ ] C4. Google Play 프로덕션 신청 (14일 요건, 현재 5일차 · 테스터 12명 충족)
- [ ] C5. Zalo 로그인 + Sign in with Apple (Zalo 계정 인증 후)
