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

## 4. 심사 제출 — ✅ 완료 (2026-08-25, "1.0 심사 대기 중")

- 사용권 계약 동의 완료 (사용자)
- 스토어 등록정보: 스크린샷 iPhone 6.5"(1284×2778) 8장 + iPad 13"(2064×2752) 8장, 프로모션 텍스트, 설명(스토어등록_정보.md), 키워드, 지원/마케팅 URL, 저작권
- 앱 정보: 카테고리 라이프스타일+건강및피트니스, 콘텐츠 권한(타사 콘텐츠 없음), 연령 등급 4+ (설문 7단계 완료)
- 개인정보: 처리방침 URL + 데이터 수집 라벨 8종(이름·이메일·전화·주소·정확한위치·사진·기타콘텐츠·사용자ID, 전부 앱 기능/신원 연결/추적 없음) **게시 완료**
- 가격 무료, **사전 주문(Pre-Order) 게시: 베트남·대한민국, 출시일 2026-10-01** (변경 가능)
- 심사 정보: 데모 demo@massa.app / massa1234, 연락처 Dongchun Park
- 빌드 1(1.0) 첨부 → **심사를 위해 제출 완료** — 현재 상태 "1.0 심사 대기 중"

## 4-1. Guideline 2.1 리젝 → 재제출 (2026-08-25 밤)

- 빌드 1이 2.1 Information Needed로 리젝. 요구 7개 항목(실기기 녹화 + 기능·대상·설정·외부서비스·지역차·규제 설명)에 영문 답변 작성 → 심사 정보 메모 + Resolution Center 회신, `massa-demo.mp4` 첨부
- 리젝 대응으로 코드 3건 수정: 채팅 화면 마크업 복구 + 프로필에 채팅 진입 버튼, 신고·차단 기능(blocks 테이블), 네이티브 앱에서 devmode(와이어프레임 UI) 차단
- **계정 삭제를 앱 내에서 완결**로 변경 (Apple 5.1.1(v)). `public.delete_my_account()` RPC를 massa-db에 설치, index.html에서 `sb.rpc('delete_my_account')` 호출. 테스트 계정 생성→삭제→재로그인 거부까지 검증 완료
- **빌드 6으로 재제출 완료** — 상태 "심사 대기 중" (제출 ID 4555e070-577b-46fd-aefe-c5deea7695bf)

## 5. 다음 할 일

1. 심사 결과 대기 (보통 1~7일)
2. 승인되면 사전 주문이 자동 게시됨 (베트남·한국, 출시일 2026-10-01 — 날짜는 가격 및 사용 가능 여부에서 변경 가능)
3. Zalo 앱 등록 (계정 본인인증 필요) → /root/massa/.env 시크릿 입력 → `docker compose up -d functions`

## 6. 작업 요령 (다음 세션 참고)

- ASC 폼은 JS 값 주입을 React가 무시함 → 스크린샷 업로드는 `shots.141-164-46-88.sslip.io`(VPS 임시 파일서버, /root/shots + caddy 컨테이너 /srv/shots) fetch → DataTransfer 주입으로 성공
- 심사 정보 저장은 UI가 POST 409로 실패 → Iris API(`/iris/v1/appStoreReviewDetails`, `/iris/v1/reviewSubmissions` + Items POST) 직접 호출로 해결, 최종 제출은 UI "제출 초안(1개) → 심사를 위해 제출" 버튼
- ASC 배포 페이지는 URL로 직접 열면 렌더링이 안 됨 → `/apps`로 먼저 들어가 SPA 내부 링크를 `.click()`으로 따라갈 것
- 빌드 번호는 `app-store-connect get-latest-*`가 항상 0을 반환해 중복 실패 → codemagic.yaml은 `$PROJECT_BUILD_NUMBER` 사용. 빌드 트리거는 codemagic.io 탭에서 `POST https://api.codemagic.io/builds`
- 첨부 파일 업로드는 GitHub raw에서 fetch → File → DataTransfer로 input[type=file]에 주입
- VPS 콘솔(noVNC)은 Shift가 전달되지 않아 `|`, `{`, `"`, 대문자를 못 씀 → `curl -s --location <raw url> -o /tmp/x.sh` 후 `sh /tmp/x.sh` 방식으로 우회

## 4. 주의사항

- 웹뷰 래핑 앱은 심사 4.2(최소 기능성) 리젝 위험 → 푸시 알림 등록 UI·네이티브 위치 사용을 심사 메모에 강조할 것.
- Zalo 로그인 추가 시 Apple 심사 4.8 때문에 Sign in with Apple도 함께 넣어야 함 (모아학원 native.js에 구현 예시 있음).
- 모아학원과 massa는 별개 앱 — 번들 ID·앱 레코드·서명 프로파일 모두 분리. Codemagic 인프라(ASC 키, 인증서 개인키)만 계정 수준에서 공유.
