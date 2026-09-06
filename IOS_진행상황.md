# iOS App Store 등록 — 진행 상황 인계서

> 새 대화에서는 이 파일을 먼저 읽고 "남은 작업"부터 이어서 진행하면 됩니다.
> 최종 갱신 2026-08-29

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

## 4-2. 2차 리젝 → build 8 재제출 (2026-08-27)

Apple이 8/26 iPad Air(M3)/iPadOS 26.6에서 심사, 세 건 지적.

- **4.0 Design** — 로그인 시 외부 Safari로 이동. 원인은 미완성 소셜 로그인 버튼 3개(Google·카카오·Zalo). VPS Supabase `/auth/v1/settings` 조회 결과 공급자가 전부 false(email·phone만 true)여서 authorize 엔드포인트가 `provider is not enabled` 에러 페이지를 Safari에 띄웠다. → 버튼과 OAuth 코드 전량 제거, 이메일 로그인만 남김
- **4.8 Login Services** — 서드파티 로그인이 사라졌으므로 해당 없음. 소셜 로그인을 다시 넣을 때 Sign in with Apple을 함께 구현하기로 함(사용자 결정)
- **2.1(a)** — "회원가입/로그인" 탭 시 무한 로딩. 원인은 핸들러에 try/catch·타임아웃 부재. → 15초 타임아웃 + 예외 처리 + 버튼 재활성화 + 실패 사유 표시
- 부가: 계정 화면에 `window.__BUILD__` 표시(codemagic.yaml에서 PROJECT_BUILD_NUMBER 주입) — 구버전 테스트로 인한 혼선 방지
- **build 8 재제출 완료**, 회신에 세 건 원인·수정 내용 기재

## 4-3. 승인 및 출시 완료 (2026-08-29)

- 8/27 23:15 UTC 심사 통과 → `PENDING_DEVELOPER_RELEASE`
- 사전 주문(한국·베트남, 2026-10-01) 해제: 가격 및 사용 가능 여부 → 사전 주문 편집 → "App Store에서 사전 주문 삭제". **주의: 해제하면 두 지역이 곧바로 "사용 불가"로 바뀌므로 "사용 가능 여부 관리"에서 한국·베트남을 다시 켜야 한다**
- "이 버전 출시" 실행 → **1.0 (build 8) READY_FOR_SALE**. 대한민국·베트남 App Store 게시 (반영까지 최대 24시간)

## 4-4. 1.0.1 업데이트 (2026-08-29)

- 실기기에서 홈 아래에 빈 화면이 보인다는 제보 → 원인은 CSS `#chat { display:flex }`가 `.screen{display:none}`을 덮어써 **채팅 화면이 홈 밑에 항상 렌더링**된 것(스크롤 높이가 정확히 2배). `#chat.on`으로 수정
- 홈 배너 3개에 `flex:1 1 150px; max-height:240px` 적용 — 남는 세로 공간을 나눠 가져 화면을 채운다 (150→189px)
- **마케팅 버전 관리**: 출시된 1.0 트레인은 닫혀 새 빌드 업로드가 거부된다(`Invalid Pre-Release Train`). codemagic.yaml이 `capacitor/package.json`의 version을 읽어 `agvtool new-marketing-version`으로 설정하도록 변경. **다음 업데이트 시 package.json version만 올리면 된다**
- build 10 → **1.0.1 심사 제출 완료**

### GitHub 푸시 권한 메모
저장소 소유자는 `karmadc070-droid`인데 PC·브라우저 자격증명은 `parkdongchun-77`이다(403). `parkdongchun-77`을 협업자로 초대·수락해 해결함. push가 응답 없이 멈추면 대기 중인 git 프로세스를 정리한 뒤 재시도할 것.

## 4-5. 1.0.1 출시 + 1.0.2 업데이트 (2026-08-29)

- **1.0.1 심사 통과 → 출시 완료** (한국·베트남, 상태 "배포 준비됨")
- 이어서 1.0.2 준비. 담긴 내용은 아래 네 가지다.

**(1) 운영 화면 23개를 앱에서 분리**
관리자 13개 + 파트너 10개를 index.html에서 걷어내고 `admin.moahagwon.com`으로 옮겼다. 지우기 전에 admin.html에 해당 화면·로더가 모두 있는지 먼저 확인했다. index.html 334KB → 224KB, 화면 47개 → 24개. Guideline 2.3.1(숨겨진 기능) 소지도 함께 없앴다.

**(2) 다국어 전면 수정**
증상은 "되는 것과 안 되는 것이 섞여 있다"였고 원인은 사전이 아니라 엔진이었다.
- 정해진 CSS 클래스만 훑고 자식 태그가 있으면 건너뛰던 방식 → 텍스트 노드 전체 순회(`translateTree`)
- `MutationObserver`로 나중에 그려지는 목록·오버레이까지 자동 번역
- `alert`/`confirm`/`prompt` 래핑 — 호출부를 고치지 않고 번역 경로에 태움
- 언어 선택을 localStorage에 저장 (이전에는 새로고침마다 한국어로 되돌아갔다)
- DICT 202개 → 355개, 중국어·일본어 누락 56개 → 0개
- 미번역 한국어 텍스트 노드 190개 → 0개(예약 플로우 4개 화면 4개 언어 확인)
- 운영 콘솔은 한국어·베트남어 2개 언어로 제한

**(3) 예약 확인 화면이 선택 내용을 반영하지 않던 결함**
`#confirm` 요약이 마크업에 하드코딩돼 있어 누굴 고르든 `Linh N. / 6월 7일 / 롯데호텔 2104호`가 보였다. `fillConfirm()`으로 실제 선택값을 채우게 했다. (DB 저장은 원래 정상이었고 표시만 어긋났다.)

**(4) 요일 번역이 날짜를 망가뜨리던 버그 — 가장 위험했던 것**
날짜 칩에서 `textContent.replace(/\D/g,'')`로 날짜를 읽는데, 요일을 번역하자 **베트남어 수요일 `T4`의 숫자가 섞여** `06/10`이 `06/410`이 됐다. 표시뿐 아니라 `submitBooking()`의 저장 경로도 같은 코드여서 **베트남어 사용자는 잘못된 날짜로 예약될 수 있었다.** `selectedDayNum()`으로 요일 라벨을 뺀 뒤 숫자를 읽도록 고쳤다.

**교훈**: 화면에 보이는 문자열은 번역되면 내용이 바뀐다. 거기서 값을 파싱하면 안 된다. 다국어를 붙일 때는 문자열 파싱 코드부터 찾아볼 것.

- 번역 추가는 `scripts/i18n-add.py`를 고쳐 다시 실행한다(같은 키는 덮어쓰므로 몇 번을 돌려도 결과가 같다)
- **build 16 → 1.0.2 심사 제출 완료** (build 15 는 프로필 상세 다국어 수정 전이라 폐기)

## 5. 다음 할 일

1. 1.0.2 심사 결과 대기
2. 메일 템플릿 한국어화 (비밀번호 재설정 메일이 아직 GoTrue 기본 영문)
3. Resend API 키 회전 (작업 중 화면에 노출됨)
4. Google Play 프로덕션 신청 (14일 요건)
5. Zalo 앱 등록 (계정 본인인증 필요) → /root/massa/.env 시크릿 입력 → `docker compose up -d functions`
6. Zalo 로그인 추가 시 Sign in with Apple 동반 필요 (Guideline 4.8)

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

---

## 1.0.5 (build 19) — 2026-09-06

**Codemagic build #19 성공 · TestFlight 업로드 완료.** 남은 것은 App Store 심사 제출뿐이다.

빌드 파이프라인이 저장소 루트의 `index.html` 을 그대로 `www/` 로 복사하므로
웹에 반영한 것이 자동으로 앱에도 들어간다. 마케팅 버전은 `capacitor/package.json` 한 곳에서만 관리한다.

### 이 버전에 들어간 것
1. **가격 개편** — 마사지 전 종류 60분 500,000 · 90분 600,000 · 120분 700,000 (GLOW 하노이 시세 기준).
2. **코스 11종으로 확대** — 아로마·스웨디시·타이 3종만 고를 수 있던 것을
   핫스톤·발·머리·목어깨·등·스포츠·부항·오일없이까지 11종으로. 코스 화면을 DB 기반으로 다시 짰다.
3. **★ 청구 금액 버그 두 개**
   - 스웨디시·타이에 120분이 없어, 120분을 고른 손님이 **60분 가격(500,000₫)으로 예약**되던 문제.
   - 코스를 못 찾으면 **850,000₫ 을 임의로 물리던 폴백**. 둘 다 제거.
4. 내린 서비스가 고객 목록에 그대로 보이던 문제 (`is_active` 필터).
5. 유입 계측 — 앱 실행 기록(기기 랜덤 ID·날짜만). 개인정보처리방침에 항목 추가.
6. 문의 주소를 `support@massaviet.com` 으로.

### 릴리즈 노트 초안 (ASC "이번 버전의 새로운 기능")
```
· 마사지 코스를 11종으로 늘렸습니다. 핫스톤, 발·다리, 머리, 목·어깨, 등, 스포츠,
  부항, 오일 없는 마사지를 새로 고르실 수 있습니다.
· 모든 코스의 요금을 60분 500,000₫ / 90분 600,000₫ / 120분 700,000₫ 로 정리했습니다.
· 예약 금액이 실제 코스와 다르게 계산되던 문제를 바로잡았습니다.
· 판매하지 않는 코스가 목록에 남아 있던 문제를 고쳤습니다.
```

### 제출 완료 — 2026-09-06 · **1.0.5 (build 20) WAITING_FOR_REVIEW**

build 19 를 만든 뒤 **왁싱 예약이 막히는 것을 발견**해 고치고 build 20 을 다시 만들었다.
제출된 것은 build **20** 이다.

**막혔던 절차와 푼 방법**
1. `1.0.4` 가 `PENDING_DEVELOPER_RELEASE`(심사 통과·출시 대기)로 자리를 잡고 있어
   `POST /iris/v1/appStoreVersions` 가 `You cannot create a new version of the App in the current state` 로 거부됐다.
   애플은 앱당 편집 가능한 버전을 하나만 둔다.
2. `DELETE` 도 `STATE_ERROR` 로 막혔다. → 화면의 **"출시를 취소"** 를 눌러 `DEVELOPER_REJECTED` 로 되돌렸다.
3. 그러면 그 버전 레코드가 편집 가능해진다. **버전 문자열을 1.0.4 → 1.0.5 로 PATCH** 하고
   `relationships/build` 에 build 20 을 붙였다. 새 버전을 만들 필요가 없었다.
4. 릴리즈 노트는 `appStoreVersionLocalizations` PATCH 로 저장(200).
5. **제출은 API 로 안 된다.** `PATCH reviewSubmissions {submitted:true}` 는 응답이 없고 상태가 안 바뀐다.
   화면의 **"제출 초안(1개)" → "심사를 위해 제출"** 을 눌러야 한다. (1.0.2 때와 같다)

⚠️ ASC 는 URL 로 직접 열면 렌더링이 안 된다. `/apps` 로 들어가 SPA 링크를 눌러 이동할 것.
⚠️ 버튼이 `<a>` 인 경우가 있어 `querySelectorAll('button')` 로는 안 잡힌다.
   좌표 클릭도 확대 배율 때문에 어긋난다. `pointerdown/mousedown/pointerup/mouseup/click` 을
   요소에 직접 dispatch 하는 방식이 확실하다.
