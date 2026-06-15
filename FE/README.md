# 단밥 앱 (Danbab) — Flutter 모바일 클라이언트

단국대학교 학식 선주문 서비스의 Flutter 모바일 앱입니다.  
Android / iOS를 지원하며, 학생식당 메뉴 조회, 선주문·결제, AI 메뉴 추천, 실시간 조리 알림 기능을 제공합니다.

---

## 화면 구성

| 화면 | 설명 |
|------|------|
| 로그인 | Google OAuth 2.0 또는 학번 + OTP 이메일 인증으로 로그인 |
| 회원가입 | 이름·학번·비밀번호 입력 → OTP 인증 후 계정 생성 |
| 홈 | 학생식당 / 카페 / 천원의 학식 / AI 스마트 추천 진입점 |
| 학생식당 메뉴 | 식당별 메뉴 목록 조회 및 장바구니 담기 |
| 천원의 학식 | 1,000원 학생 식사 메뉴 안내 |
| 장바구니 | 주문 전 검증 및 수량 조정 |
| 결제 | Toss Payments WebView 결제 |
| AI 메뉴 추천 | 취향 기반·날씨 기반·인기 메뉴 추천 |
| 식권 | 디지털 식권 조회 및 QR 스캔 |
| 주문 내역 | 최근 주문 목록 및 상세 조회 |
| 리뷰 | 메뉴별 리뷰 조회 및 작성 |
| 내 정보 | 프로필 확인·비밀번호 변경·로그아웃·회원 탈퇴 |

하단 탭 바: **홈 · 식권 · 주문 내역 · 내 정보**

---

## 기술 스택

| 항목 | 내용 |
|------|------|
| 언어 | Dart |
| 프레임워크 | Flutter (SDK ^3.12.0) |
| 플랫폼 | Android, iOS |
| 인증 | `google_sign_in` ^6.2.2 |
| HTTP | `http` ^1.6.0 |
| 로컬 저장 | `shared_preferences` ^2.3.3 |
| 푸시 알림 | `flutter_local_notifications` ^18.0.1 |
| QR 스캔 | `mobile_scanner` ^5.2.3 |
| 결제 WebView | `webview_flutter` ^4.10.0 |

---

## 프로젝트 구조

```
FE/
├── lib/
│   ├── main.dart                    # 앱 진입점, 하단 탭 바 구성
│   ├── app_theme.dart               # 색상 · 텍스트 스타일 상수
│   ├── api_service.dart             # BE REST API 연동 (JWT 자동 갱신 포함)
│   ├── notification_service.dart    # FCM 로컬 알림 초기화 및 미읽음 관리
│   │
│   ├── login_screen.dart            # 로그인 (Google / 학번)
│   ├── signup_screen.dart           # 회원가입
│   ├── otp_verification_screen.dart # OTP 이메일 인증
│   │
│   ├── home_dashboard_screen.dart   # 홈 대시보드
│   ├── cafeteria_menu_screen.dart   # 학생식당 메뉴
│   ├── thousand_won_meal_screen.dart# 천원의 학식
│   ├── breakfast_screen.dart        # 조식 메뉴
│   ├── cart_screen.dart             # 장바구니
│   ├── payment_screen.dart          # 결제 화면
│   ├── toss_payment_webview.dart    # Toss Payments WebView
│   │
│   ├── ai_menu_screen.dart          # AI 메뉴 추천
│   ├── ticket_screen.dart           # 디지털 식권
│   ├── order_history_screen.dart    # 주문 내역
│   ├── review_screen.dart           # 리뷰 목록
│   ├── review_write_screen.dart     # 리뷰 작성
│   ├── profile_screen.dart          # 내 정보
│   └── screens/
│       └── review_screen.dart
│
├── assets/
│   └── images/
│       └── danbap_logo.png
│
├── android/                         # Android 네이티브 설정
├── ios/                             # iOS 네이티브 설정
└── pubspec.yaml
```

---

## 설치 및 실행

### 사전 준비

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치 (3.12.0 이상)
- Android Studio 또는 Xcode 설치
- BE 서버 실행 중 (기본 포트 3000)

### 1. 의존성 설치

```bash
cd FE
flutter pub get
```

### 2. 앱 실행

```bash
# Android 에뮬레이터 / 실기기
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com

# iOS 시뮬레이터
flutter run -d ios --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

> `GOOGLE_WEB_CLIENT_ID`는 Google Cloud Console에서 발급한 **웹 애플리케이션** 타입 OAuth 클라이언트 ID입니다.  
> Android에서 Google 로그인 시 idToken을 정상적으로 수신하려면 반드시 이 값이 필요합니다.

### 3. BE 서버 주소 설정

[lib/api_service.dart](lib/api_service.dart)에서 자동으로 환경을 감지합니다.

| 환경 | 주소 |
|------|------|
| Android 에뮬레이터 | `http://10.0.2.2:3000` |
| iOS 시뮬레이터 / 웹 | `http://localhost:3000` |

실기기 테스트 시 `baseUrl`을 서버의 실제 IP로 변경하세요.

---

## Google 로그인 설정

1. [Google Cloud Console](https://console.cloud.google.com)에서 OAuth 2.0 클라이언트 ID 생성
   - **웹 애플리케이션** 타입 → 클라이언트 ID 발급
   - **Android** 타입 → 앱 SHA-1 지문 등록
2. `google-services.json`을 `android/app/`에 배치
3. `flutter run` 실행 시 `--dart-define=GOOGLE_WEB_CLIENT_ID=...` 전달

```bash
# SHA-1 지문 확인 (디버그 키스토어)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
```

---

## 빌드

```bash
# Android APK
flutter build apk --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id

# Android App Bundle (Play Store 배포용)
flutter build appbundle --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id

# iOS (Xcode 필요)
flutter build ios --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id
```
