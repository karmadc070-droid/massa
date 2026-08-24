# iOS App Store 등록 — 진행 상황 인계서

> 새 대화에서는 이 파일을 먼저 읽고 "남은 작업"부터 이어서 진행하면 됩니다.
> 최종 갱신 2026-08-23

## 1. 핵심 좌표

| 항목 | 값 |
|---|---|
| Apple Developer 팀 | dongchun park (박동춘) · Team ID `GRF3HK77HU` |
| 번들 ID | `app.massa.hanoi` (explicit, 푸시 알림 capability 켜짐) |
| App Store Connect 앱 | massa — 홈 마사지·홈뷰티 · Apple ID `6804698319` · SKU massa-hanoi-001 · 기본 언어 한국어 |
| 빌드 방식 | Codemagic (mac_mini_m2) — 모아학원에서 검증된 파이프라인 이식 |
| iOS 셸 | Capacitor 8 (capacitor/ 디렉터리), 푸시·위치 플러그인 포함 |

## 2. 완료된 것 (2026-08-23)

- [x] 번들 ID `app.massa.hanoi` 등록 (Certificates, Identifiers & Profiles)
- [x] App Store Connect 앱 레코드 생성
- [x] `capacitor/` 스캐폴드: package.json, capacitor.config.json, native-src/native.js(위치 shim + 푸시), assets/icon.png(1024)·splash.png(2732)
- [x] `codemagic.yaml` (iOS 워크플로) — www 복사, 네이티브 번들 주입, cap add ios(CocoaPods), Info.plist 권한 문구, APNs entitlements, 서명 자동화, TestFlight 업로드

## 3. 남은 작업 (이 순서대로)

1. **Apple Developer 사용권 계약 동의** — App Store Connect 상단 경고. 계정 소유자가 developer.apple.com → 계정에서 동의해야 새 앱 제출 가능. (사용자 직접)
2. **Codemagic에 massa 앱 연결** — codemagic.io 로그인 → Add application → GitHub karmadc070-droid/massa 선택.
   - 모아학원과 같은 팀이면 App Store Connect 통합(moahagwon_asc_key)과 ios_signing 그룹(CERTIFICATE_PRIVATE_KEY) 재사용 가능.
   - 모아학원 Codemagic이 parkdongchun-77 GitHub 계정에 연결돼 있다면 karmadc070-droid repo 접근 권한 추가 필요.
3. **첫 빌드 실행** (ios-appstore 워크플로) → TestFlight 업로드 확인.
4. **App Store 등록정보 작성** — 스크린샷(6.7" 1290×2796 등), 설명(스토어등록_정보.md 재활용), 개인정보 URL https://massa-seven.vercel.app/privacy.html, 심사 메모(데모 계정 demo@massa.app / massa1234).
5. **개인정보 보호(누트리션 라벨) 설문** — Play 데이터 보안 답변(massa_data_safety.csv) 기준으로 작성.
6. **심사 제출** → 승인 후 **사전 주문(Pre-Order)** 설정 (출시일 지정, 베트남 지역).

## 4. 주의사항

- 웹뷰 래핑 앱은 심사 4.2(최소 기능성) 리젝 위험 → 푸시 알림 등록 UI·네이티브 위치 사용을 심사 메모에 강조할 것.
- Zalo 로그인 추가 시 Apple 심사 4.8 때문에 Sign in with Apple도 함께 넣어야 함 (모아학원 native.js에 구현 예시 있음).
- 모아학원과 massa는 별개 앱 — 번들 ID·앱 레코드·서명 프로파일 모두 분리. Codemagic 인프라(ASC 키, 인증서 개인키)만 계정 수준에서 공유.
