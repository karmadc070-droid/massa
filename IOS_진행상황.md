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

## 3. 빌드 파이프라인 — ✅ 가동 (2026-08-24)

- Codemagic massa 앱 연결 완료 (public repo URL 방식, 앱 ID 6a8c482d21afff14a210fad7)
- CERTIFICATE_PRIVATE_KEY 등록 완료 (ios_signing 그룹, `C:\Users\user\Claude\apple-keys\codemagic_certificate_private_key.pem` 재사용)
- **빌드 1 성공**: IPA 생성 → App Store Connect 업로드·처리 완료 → 수출 규정 답변(비면제 암호화 없음) → 상태 "제출 준비 완료"
- 빌드 시 마지막 자동 단계(TestFlight 베타 심사 제출)만 "테스트 정보 미입력"으로 실패했음 — 외부 테스터 쓸 때만 필요, 무해
- codemagic.yaml에 ITSAppUsesNonExemptEncryption=false 추가함 (다음 빌드부터 암호화 질문 생략)

## 4. 남은 작업 (이 순서대로)

1. **Apple Developer 사용권 계약 동의** — 계정 소유자가 developer.apple.com에서 동의해야 심사 제출 가능. (사용자 직접)
2. **App Store 등록정보 작성** — 스크린샷(6.7" 1290×2796 등), 설명(스토어등록_정보.md 재활용), 개인정보 URL https://massa-seven.vercel.app/privacy.html, 심사 메모(데모 계정 demo@massa.app / massa1234).
3. **개인정보 보호(누트리션 라벨) 설문** — Play 데이터 보안 답변(massa_data_safety.csv) 기준으로 작성.
4. **심사 제출** → 승인 후 **사전 주문(Pre-Order)** 설정 (출시일 지정, 베트남 지역).
5. (선택) TestFlight 테스트 정보 입력 + 내부 테스터 그룹 생성 → 실기기 테스트.

## 4. 주의사항

- 웹뷰 래핑 앱은 심사 4.2(최소 기능성) 리젝 위험 → 푸시 알림 등록 UI·네이티브 위치 사용을 심사 메모에 강조할 것.
- Zalo 로그인 추가 시 Apple 심사 4.8 때문에 Sign in with Apple도 함께 넣어야 함 (모아학원 native.js에 구현 예시 있음).
- 모아학원과 massa는 별개 앱 — 번들 ID·앱 레코드·서명 프로파일 모두 분리. Codemagic 인프라(ASC 키, 인증서 개인키)만 계정 수준에서 공유.
