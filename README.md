# mㅏssㅏ (마싸)

베트남 하노이 거점 프리미엄 홈 웰니스·그루밍 온디맨드 플랫폼 프로토타입.

## 구성
- `마싸_고객앱_와이어프레임.html` — 고객·파트너·관리자 3역할 통합 프로토타입 (Supabase 실데이터 연동)
- `마싸_전체흐름_정리.md` — 서비스 전체 흐름·DB 구조 정리
- `소셜로그인_설정가이드.md` — Google·Kakao·Zalo 로그인 설정 절차
- `config.example.js` — 로컬 설정 예시 (복사해서 `config.js` 로 사용)

## 실행
로컬에서 http 주소로 열어야 소셜 로그인·AI 변환·GPS가 정상 동작합니다.

```bash
python -m http.server 8000
# http://localhost:8000/마싸_고객앱_와이어프레임.html
```

## 주의
`.env` 와 `config.js` 는 API 키를 담고 있어 `.gitignore` 로 제외됩니다. 저장소에 키를 올리지 마세요.
