# Apple Guideline 2.1 답변 (제출용 영문)

> 녹화 파일이 준비되면 이 문안과 함께 App Store Connect 메시지로 회신한다.
> 항목 1(녹화)은 첨부, 2~7은 아래 텍스트.

---

Thank you for reviewing massa. Please find the requested information below.

**1. Screen recording**
The attached screen recording was captured on a physical iPhone running the TestFlight build. It demonstrates the app launch, the signed-in account screen, browsing verified therapists near the user, and the complete core booking flow (select therapist → view profile → choose course and duration → choose date and time → enter the hotel/home address → booking confirmed with a booking number).

Please note: the recording was captured on build 1. Build 5 (uploaded with this reply) additionally exposes the in-app chat entry point and the report/block controls described in item 4 below. Everything else in the recording is unchanged.

**2. Devices and OS tested on**
- iPhone (physical device) — latest iOS, via TestFlight, build 1.0 (5)
- Android devices via Google Play internal testing (same hybrid codebase)

**3. App functions and target audience**
massa is an on-demand home massage and home beauty booking platform for Hanoi, Vietnam. Customers (adults 18+, including local residents, business travelers and tourists staying in hotels) can book verified massage therapists and beauty professionals to visit their home or hotel room at a chosen time. The app solves the problem of finding trustworthy, vetted therapists on demand: providers pass a 3-step verification (license check, identity check, in-person interview) before being listed. Payment is made on-site after the service (card, MoMo/ZaloPay QR, or cash) — the app itself processes no payments.

**4. Setup and access instructions**
No special hardware, environment or configuration is required. Launch the app → tap the 계정 (Account) tab at the bottom right → sign in with the demo account listed in App Review Information (demo@massa.app / massa1234).

- Booking flow: 탐색 (Explore) tab → "마사지 홈서비스" → select a therapist → 예약 (Book) → choose course and duration → choose date and time → enter the address or hotel name and room number → 예약 확정 (Confirm). A booking number is issued.
- In-app chat: open any therapist profile and tap "💬 채팅으로 문의하기" near the top of the profile.
- Report objectionable content: therapist profile → scroll to the bottom → "🚩 이 제공자 신고하기", or the "🚩 신고" button in the chat header. Reports are reviewed by our moderation team within 24 hours.
- Block a user: therapist profile → "⛔ 이 제공자 차단하기", or the "⛔ 차단" button in the chat header. Blocked providers disappear from the listing immediately.
- Account deletion: 계정 (Account) tab → scroll to 계정 삭제 (Delete account).

The demo account also has partner (therapist) permissions enabled so that the reviewer can inspect the partner-side screens (schedule, earnings, customer chat) from the same login. A regular customer account does not see those rows.

**5. External services used**
- Self-hosted Supabase (PostgreSQL, Auth, Storage, Realtime) on our own VPS (Vultr, Seoul region) — application database, authentication, image storage, realtime chat: https://massa.141-164-46-88.sslip.io
- Google Gemini API (server-side only, via edge function) — optional profile photo styling for provider onboarding
- Capacitor (WKWebView hybrid shell) with native push notifications (APNs) and native geolocation
- No third-party ads, no analytics SDKs, no payment processors (payment is offline, on-site after service)

**6. Regional differences**
None. The app functions identically in all regions. The service currently operates in Hanoi, Vietnam; the app is offered on the App Store in Vietnam and South Korea. Languages: Korean, Vietnamese, English, Japanese, Chinese.

**7. Regulated industry / third-party material**
massa is a booking/matchmaking platform for non-medical relaxation massage and beauty services (nail, waxing, scrub). It does not provide medical treatment, telehealth, or any regulated healthcare service, and contains no protected third-party material. All content (photos, descriptions) is provided by our verified partner providers under our terms of service.

---

## 녹화 촬영 가이드 (사용자용, 한국어)

iPhone 설정 → 제어 센터 → 화면 기록 추가 후, 아래 순서로 한 번에 촬영 (2~4분):

1. 홈 화면에서 massa 앱 아이콘 탭 → 실행 (앱 실행 장면부터 시작 필수)
2. 계정 탭 → 회원 가입 화면 잠깐 보여주기 → 로그인 (demo@massa.app / massa1234)
3. 홈 → 마사지 홈서비스 → 테라피스트 선택 → 코스 → 시간 → 위치 입력 → 예약 확인
4. (위치 권한 팝업이 뜨면 그 장면 포함 — 내 근처/지도 검색 탭)
5. 테라피스트 프로필 → 아래로 스크롤 → "🚩 신고하기" 탭 → 사유 입력 → 접수 확인
6. 채팅 열기 → 메시지 1개 전송 → 상단 "⛔ 차단" 탭 → 확인 (목록에서 사라짐 확인)
7. 계정 → 계정 삭제 화면 진입 (실제 삭제는 안 해도 됨, 화면만)

완료 후 영상 파일(.mp4/.mov)을 massa 폴더에 넣고 알려주세요. 500MB 이하 권장.
