# 단밥 (Danbab) — 단국대학교 학식 선주문 서비스

단국대학교 학생들이 학교 식당 메뉴를 미리 주문하고 결제한 뒤, 완성되면 알림을 받는 모바일 선주문 플랫폼입니다.

---

## 주요 기능

- **Google 로그인** — `@dankook.ac.kr` 계정 전용 OAuth 2.0 인증
- **학식 선주문 · 결제** — Toss Payments 연동, 결제 후 주문 확정
- **실시간 조리 현황** — WebSocket으로 주방 상태를 앱에 즉시 반영
- **FCM 푸시 알림** — 조리 완료 시 알림 수신
- **AI 메뉴 추천** — 사용자 취향 · 날씨 기반 메뉴 추천
- **조리 시간 예측** — 주문량을 분석해 예상 대기 시간 표시
- **주방 디스플레이** — 식당별 접수 주문 확인 · 완료 처리 화면

---

## 아키텍처

```
┌─────────────────────────────┐
│   Flutter 앱 (Android/iOS)  │  ← 학생 / 주방 직원
└────────────┬────────────────┘
             │ REST API / WebSocket
             ▼
┌────────────────────────────────────────┐
│   BE Server  (Node.js · Express · 3000) │
│   Prisma ORM · SQLite/PostgreSQL        │
│   WebSocket · Toss Payments · FCM       │
└───────────────┬────────────────────────┘
                │ HTTP
                ▼
┌────────────────────────────────────────┐
│   AI Server  (Python · FastAPI · 8000) │
│   메뉴 추천 · 조리 시간 예측 · 크롤링   │
└────────────────────────────────────────┘
```

---

## 디렉토리 구조

```
capstone/
├── FE/                  # Flutter 모바일 앱 (단밥)
├── BE/                  # Node.js/Express REST API + WebSocket
├── AI/                  # Python/FastAPI AI 서버
└── docker-compose.yml   # BE + AI 통합 실행
```

각 디렉토리의 세부 설명 및 환경 변수는 하위 README를 참조하세요.

- [FE/README.md](FE/README.md)
- [BE/README.md](BE/README.md)
- [AI/README.md](AI/README.md)

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| **모바일** | Flutter (Dart) |
| **백엔드** | Node.js 18+, Express, Prisma, SQLite / PostgreSQL |
| **AI** | Python, FastAPI, BeautifulSoup, Docker |
| **인증** | Google OAuth 2.0 + JWT (액세스 2h / 리프레시 30d) |
| **결제** | Toss Payments API |
| **실시간** | WebSocket (`ws`) |
| **푸시 알림** | Firebase Cloud Messaging (FCM) |
| **스케줄링** | node-cron (평일 오전 7시 메뉴 자동 동기화) |
| **인프라** | Docker, Docker Compose |

---

## 빠른 시작

### 사전 준비

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 설치
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치
- Google Cloud Console에서 OAuth 2.0 클라이언트 ID 발급
- Toss Payments 테스트 키 발급
- Firebase 프로젝트 및 FCM 서비스 계정 키 발급

### 1. 저장소 클론

```bash
git clone https://github.com/jubbaki/capstone.git
cd capstone
```

### 2. 백엔드 환경 변수 설정

```bash
cp BE/.env.example BE/.env
# BE/.env 파일을 열어 각 항목을 채워넣습니다
```

### 3. BE + AI 서버 실행 (Docker)

```bash
docker-compose up --build
```

| 서버 | 주소 |
|------|------|
| BE (REST API) | `http://localhost:3000` |
| AI (FastAPI) | `http://localhost:8000` |
| AI Swagger | `http://localhost:8000/docs` |
| BE 헬스체크 | `GET /health` |

### 4. Flutter 앱 실행

```bash
cd FE
flutter pub get
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

---

## 주문 흐름

```
1. POST /orders/validate      → 장바구니 검증 + idempotencyKey 발급
2. POST /payments/confirm     → Toss 결제 승인
3. POST /orders               → 주문 생성 (WebSocket → 주방 디스플레이)
4. PATCH /kitchen/items/:id/complete → 조리 완료 (FCM + WebSocket → 고객 앱)
```

---

## 팀 구성

| 역할 | 담당 |
|------|------|
| FE (Flutter) | 팀 전체 |
| BE (Node.js) | 팀 전체 |
| AI (Python) | [Yoo, J. H.](https://github.com/YooJunHyuk123) |
