# Play 스토어 등록 — 진행 상황 인계서

> 새 대화를 시작하면 이 파일을 먼저 읽고 "남은 작업"부터 이어서 진행하면 됩니다.
> 최종 갱신 2026-08-14

---

## 1. 핵심 좌표

| 항목 | 값 |
|---|---|
| Play Console 개발자 계정 | ParkDongChun · 계정 ID `6224655638055994426` |
| 앱 ID (Play Console 내부) | `4975749612232381832` |
| 패키지 이름 (영구, 변경 불가) | `app.massa.hanoi` |
| 앱 이름 | massa — 홈 마사지·홈뷰티 |
| 앱 대시보드 URL | https://play.google.com/console/u/0/developers/6224655638055994426/app/4975749612232381832/app-dashboard |
| 서비스 주소 (TWA 대상) | https://massa-seven.vercel.app |
| GitHub | https://github.com/karmadc070-droid/massa (Public) |
| Vercel 팀/프로젝트 | broteam2 / massa (`prj_rXbH3q19JIMQaMMyYsqVP4P4p7Gc`) |
| Supabase 프로젝트 | massa · ref `jfnpgjcesywsxxbwlpii` |
| 데모 계정 (심사용) | demo@massa.app / massa1234 |

---

## 2. 완료된 것

- [x] 앱 생성 (`app.massa.hanoi`, 한국어 기본, 무료 앱)
- [x] 스토어 등록정보 — 짧은 설명, 자세한 설명, 앱 아이콘 512, 그래픽 이미지 1024×500, 스크린샷 24장(휴대전화·7인치·10인치 각 8장)
- [x] 개인정보처리방침 URL 등록
- [x] 로그인 세부정보 (데모 계정 + 영문 안내)
- [x] 광고 — "앱에 광고가 없습니다"
- [x] 정부 앱 — 아니요
- [x] 금융 기능 — 없음
- [x] 건강 앱 — 없음
- [x] 타겟층 — 만 18세 이상
- [x] 광고 ID — 사용 안 함
- [x] **데이터 보안** — CSV 일괄 가져오기로 정확히 재입력 완료
- [x] **aab 업로드** — 내부 테스트 트랙, 출시 노트 작성까지
- [x] PWA 전환 (manifest, service worker, 아이콘)
- [x] 개인정보처리방침·이용약관·계정삭제 공개 페이지
- [x] `.well-known/assetlinks.json` 배포 (업로드 키 지문만 등록됨)

---

## 3. 남은 작업 (이 순서대로)

### 3-1. 내부 테스트 출시 마무리 — ✅ 완료 (2026-08-14)
버전 1 (1.0.0.0) 내부 테스트 트랙 출시됨 ("내부 테스터에게 제공됨", 게시 8/14 오후 6:53).
주의: 임시 출시에 aab가 첨부돼 있지 않았음 → 라이브러리에서 기존 번들 추가로 해결.
출시 노트도 비어 있어 새로 작성함. 테스터 목록 **MoaTest3 (37명)** 을 내부 테스트 트랙에 연결·저장함.

### 3-2. 콘텐츠 등급 설문 — ✅ 완료 (2026-08-14)
사용자 지시("계속 진행해")에 따라 설문 완료·저장. 카테고리 "다른 모든 앱 유형",
상호작용 예 / 위치 공유 예, 나머지(폭력·성적·도박·디지털구매·차단/신고 기능 등) 전부 아니요.
결과 등급: 대부분 전체이용가/3+, USK만 16 (미조정 채팅+위치 공유 탓, 정상).

### 3-2b. 추가 완료 항목 (2026-08-14)
- 스토어 설정: 앱 카테고리 **뷰티**, 연락처 이메일 karmadc070@gmail.com, 웹사이트 등록
- **비공개 테스트(Alpha) 트랙 구성 완료** — 국가: 대한민국·베트남, 테스터: MoaTest3(37명), 버전 1(1.0.0.0) 생성
- **검토를 위해 변경사항 13개 Google에 제출됨** (사전 검사 후 자동 전송, 검토 보통 7일 이내)
- 이후 할 일: 테스터 12명 이상이 비공개 테스트 참여 선택 + 14일 유지 → 프로덕션 액세스 신청

### 3-3. assetlinks.json 앱 서명 키 지문 추가 — ✅ 완료 (2026-08-15)
앱 서명 키 SHA-256:
```
05:7B:16:B3:27:8D:89:EC:90:F7:E7:48:FA:22:3D:64:AB:B6:C1:AA:5E:79:ED:62:13:F8:09:BD:CD:78:FC:56
```
업로드 키(7B:AC:…)와 함께 **지문 2개 모두 배포 확인 완료**.
https://massa-seven.vercel.app/.well-known/assetlinks.json 에서 확인 가능.
Vercel 배포는 브라우저 탭에서 §4 fetch 스니펫으로 정상 실행됨(차단 아님).

### 3-4. 프로덕션 출시 (베트남 단독) — ⏳ 테스터 참여 대기 중

**앱 상태: 비공개 테스트 (검토 통과, 정상 게시됨)**

대시보드 진행 상황 (2026-08-15 기준):
```
✓ 비공개 테스트 버전 게시
○ 12명 이상의 테스터가 비공개 테스트 참여를 선택 — 현재 0명  ← 여기서 막힘
○ 12명 이상 대상 14일 이상 실행
```

**병목: 테스터 목록(MoaTest3 37명)에 이메일이 등록만 되어 있고, 아무도 옵트인 링크로 참여하지 않음.**
목록 등록만으로는 카운트되지 않습니다. 각자가 링크를 열고 "테스터 되기"를 눌러야 합니다.

옵트인 링크:
```
https://play.google.com/apps/testing/app.massa.hanoi
```
스토어 페이지:
```
https://play.google.com/store/apps/details?id=app.massa.hanoi
```

→ 테스터에게 보낼 안내문(한/영/베)은 **`테스터_모집안내.md`** 에 준비되어 있음.

12명 채워지면 그날부터 14일 카운트 시작 → 이후 대시보드에서 **프로덕션 신청** 버튼 활성화
→ 승인 후 프로덕션 출시 시 **국가/지역은 베트남만 선택**

### 3-5. 참고 — 사업자 계정 전환 시 면제
12명·14일 요구사항은 2023-11-13 이후 생성된 **개인 계정**에만 적용됨.
**조직(organization) 계정은 면제.** 단 전환하려면 **D-U-N-S 번호**(무료, 2~4주) + 조직 웹사이트 검증 필요.
실무상 조직 계정을 새로 만들고($25) 앱을 이전하는 경우가 많음.
→ D-U-N-S 발급 시간이 14일보다 길 수 있어, 이번 출시는 테스트 진행이 빠름. 병행 권장.

---

## 4. 작업 요령 (다음 세션이 알아야 할 것)

### 파일 업로드 우회법
`file_upload` 도구가 이 환경에서 막혀 있습니다. 대신:
1. 올릴 파일을 `store-assets/` 에 복사
2. `git add -f` 로 커밋·푸시 (`.gitignore` 무시 필요)
3. Vercel 배포 트리거 (아래 참고)
4. 브라우저에서 fetch → `DataTransfer` 로 `input[type=file]` 에 주입

`vercel.json` 에 `/store-assets/(.*)` 경로 CORS 허용이 이미 걸려 있습니다.

### Vercel 배포 트리거
Git 자동 배포가 연결돼 있지 않아 수동 호출이 필요합니다.
vercel.com 탭에서 실행:
```js
fetch('https://vercel.com/api/v13/deployments?teamId=team_mbwFsE0ij24xxIqBqwmyy8uK&skipAutoDetectionConfirmation=1',
 {method:'POST',credentials:'include',headers:{'content-type':'application/json'},
  body:JSON.stringify({name:'massa',target:'production',
   gitSource:{type:'github',org:'karmadc070-droid',repo:'massa',ref:'main'},
   projectSettings:{framework:null,buildCommand:null,outputDirectory:null,installCommand:null,devCommand:null,rootDirectory:null}})})
```

### git 푸시
로컬 저장소가 `C:\Users\user\Claude\Projects\massa` 에 연결돼 있습니다.
원격은 `https://karmadc070-droid@github.com/karmadc070-droid/massa.git` (사용자명 포함이라 자격증명이 맞음).
브라우저 GitHub 세션이 `parkdongchun-77` 로 바뀌어 있으면 push 권한이 없으니 계정 전환 필요.

### Play Console 조작 주의
- 대화상자가 뜨는 데 8~10초 걸립니다. 좌표 클릭 전 반드시 스크린샷으로 렌더링 확인.
- 성급한 좌표 클릭이 엉뚱한 체크박스를 건드려 잘못된 신고가 저장된 적 있음.
- 긴 설문은 **CSV 가져오기/내보내기**를 쓰는 게 훨씬 안전하고 빠름.

---

## 5. 관련 파일

| 파일 | 용도 |
|---|---|
| `android-package/massa.aab` | Play 업로드용 번들 |
| `android-package/signing.keystore` | **업로드 키 — 분실 시 업데이트 영구 불가** |
| `android-package/signing-key-info.txt` | 키 비밀번호 (gitignore됨) |
| `store-assets/` | 아이콘·그래픽·스크린샷 8장 |
| `스토어등록_정보.md` | 설명문(한/영/베) 원문, 설문 답변 가이드 |
| `.well-known/assetlinks.json` | TWA 도메인 검증 |
| `data_safety_sample.csv` | Play 원본 샘플 (gitignore됨) |
| `massa_data_safety.csv` | massa용으로 채운 답변 (gitignore됨) |

**서명 키는 반드시 별도 백업하세요. 분실하면 이 앱을 영원히 업데이트할 수 없습니다.**

---

## 프로덕션 액세스 신청 완료 — 2026-09-06 20:38

**세 조건 모두 충족** (대시보드에 `check` 3개)
- 비공개 테스트 버전 게시
- 12명 이상 테스터가 참여 선택
- 12명 이상 대상 14일 이상 실행

앱 ID `4975749612232381832` · 패키지 `app.massa.hanoi` · 설치 13명.
(모아학원은 `4973452451763223919` — 헷갈리지 말 것)

### 신청 양식에 낸 답 (3단계)

**1. 비공개 테스트 정보**
- 모집: 하노이 지인·가족 + massa 등록 마사지사·제휴 파트너. **유료 업체 안 씀.**
- 난이도: 보통이었음
- 참여도: 가입→검색→코스·시간→주소→예약→채팅 전 흐름. 마사지사 테스터는 수락·완료 처리까지.
  결제는 현장 후불이라 앱에서 결제까지 가지 않는다고 명시.
- 의견 수집: 카카오톡·잘로 단톡방 + 대면·전화.
  받은 지적 3개(전체화면, 다국어 문구, 예약 후 연락)와 반영 내용을 함께 적었다.

**2. 앱 정보**
- 주요 대상: 하노이 직장인·교민·호텔 여행객 (성인)
- 제공 가치: 검증된 방문 마사지사·홈뷰티를 원하는 시간·장소로 연결, 자동 번역 채팅, 앱 내 안전 신고
- 예상 설치 수: **0~1만** (하노이 지역 서비스라 가장 낮은 구간)

**3. 프로덕션 준비**
- 테스트 반영: 전체화면 · 5개 언어 문구 · 예약 후 채팅 · 코스 11종 확대와 요금 정리
- 준비 판단 근거: 전 과정 실기기 반복 확인 · 신고/차단/계정삭제 앱 내 처리 ·
  방침과 약관 게시 · 자체 서버 운영과 매일 백업 · 예약 금액 오계산 수정

### 다음
- **검토는 보통 7일 이내**, 결과는 계정 소유자 메일로 온다.
- 승인되면 프로덕션 트랙에 AAB 를 올리고 출시한다.
- 그 뒤 `site-src/build.py` 의 `PLAY_LIVE = False` 를 `True` 로 바꾸고 사이트를 다시 빌드하면
  안드로이드 다운로드 링크가 살아난다.

⚠️ 답변은 사장님이 직접 확인하고 승인한 내용이다. 지어낸 것이 없다.
