# Co-Talk Flutter

Co-Talk은 실시간 메시징 애플리케이션입니다. Flutter로 개발되었으며, BLoC 패턴을 사용한 클린 아키텍처를 기반으로 합니다.

## 주요 기능

- 실시간 메시징 (WebSocket/STOMP)
- 사용자 인증 및 인가
- 친구 관리
- 채팅방 관리
- 채팅 사진 갤러리 저장 (전체 화면·길게 누르기 메뉴)
- 메시지 내 URL 감지·미리보기 (도메인 패턴·정규화 지원)
- 푸시 알림 (FCM·데스크톱 WebSocket, 앱 아이콘 반영)
- 멀티 플랫폼 지원 (iOS, Android, macOS, Windows)

## 기술 스택

- **프레임워크**: Flutter 3.8.1+
- **상태 관리**: BLoC (flutter_bloc)
- **네트워킹**: Dio
- **WebSocket**: STOMP (stomp_dart_client)
- **로컬 저장소**: flutter_secure_storage, shared_preferences
- **의존성 주입**: GetIt, Injectable
- **라우팅**: GoRouter
- **UI**: Material Design

## 프로젝트 구조

```
lib/
├── app.dart                 # 앱 진입점
├── main.dart               # 메인 함수
├── core/                   # 핵심 기능
│   ├── constants/         # 상수
│   ├── errors/            # 에러 처리
│   ├── network/           # 네트워크 설정
│   ├── router/            # 라우팅 설정
│   ├── theme/             # 테마 설정
│   └── utils/             # 유틸리티
├── data/                   # 데이터 레이어
│   ├── datasources/       # 데이터 소스
│   ├── models/            # 데이터 모델
│   └── repositories/      # 리포지토리 구현
├── domain/                 # 도메인 레이어
│   ├── entities/          # 엔티티
│   ├── repositories/      # 리포지토리 인터페이스
│   └── usecases/          # 유스케이스
├── presentation/           # 프레젠테이션 레이어
│   ├── blocs/             # BLoC 상태 관리
│   ├── pages/             # 화면
│   └── widgets/           # 위젯
└── di/                     # 의존성 주입 설정
```

## 시작하기

### 필수 요구사항

- Flutter SDK 3.8.1 이상
- Dart SDK
- iOS 개발: Xcode (macOS)
- Android 개발: Android Studio
- macOS 개발: Xcode
- Windows 개발: Visual Studio

### 설치

1. 저장소 클론:
```bash
git clone https://github.com/with-co-talk/co-talk-flutter.git
cd co-talk-flutter
```

2. 의존성 설치:
```bash
flutter pub get
```

3. 코드 생성 (의존성 주입 및 JSON 직렬화):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 실행

- iOS:
```bash
flutter run -d ios
```

- Android:
```bash
flutter run -d android
```

- macOS:
```bash
flutter run -d macos
```

- Windows:
```bash
flutter run -d windows
```

### 알림(푸시) 아이콘 (iOS / macOS / Windows)

iOS, macOS, Windows에서는 알림에 **앱 아이콘**이 사용됩니다. 알림에 Co-Talk 아이콘이 보이려면:

1. `assets/icons/app_icon.png`가 Co-Talk 앱 아이콘 이미지인지 확인합니다.
2. 다음 명령으로 모든 플랫폼 앱 아이콘을 재생성합니다:
```bash
dart run flutter_launcher_icons
```
3. 앱을 다시 빌드·실행합니다.

Android는 알림 설정에서 `@mipmap/ic_launcher`를 사용하므로, 위 명령으로 생성된 런처 아이콘이 알림에도 적용됩니다.

## 테스트

```bash
# 모든 테스트 실행
flutter test

# 커버리지 포함 테스트
flutter test --coverage
```

## 빌드

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### macOS
```bash
flutter build macos --release
```

### Windows
```bash
flutter build windows --release
```

## 개발 가이드

### 아키텍처

이 프로젝트는 Clean Architecture 원칙을 따릅니다:

- **Presentation Layer**: UI 및 상태 관리 (BLoC)
- **Domain Layer**: 비즈니스 로직 및 엔티티
- **Data Layer**: 데이터 소스 및 리포지토리 구현

### 코드 스타일

프로젝트는 `flutter_lints`를 사용하여 코드 스타일을 유지합니다.

### 의존성 주입

`get_it`과 `injectable`을 사용하여 의존성 주입을 관리합니다. 새로운 의존성을 추가한 후 다음 명령어를 실행하세요:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 문서

- **[CHANGELOG.md](./CHANGELOG.md)** — 버전별 변경 이력 (Added / Changed / Fixed 등)
- **[docs/DEV_LOG.md](./docs/DEV_LOG.md)** — 개발자 블로그 형식 정리 (배경·구현·결정 요약)

## 라이선스

이 프로젝트는 with-co-talk 조직의 소유입니다.

## 기여

기여를 환영합니다! 이슈를 열거나 Pull Request를 제출해주세요.
