# Project Rules for Claude

## Development Approach

### TDD (Test-Driven Development) - MANDATORY
모든 코드 변경은 TDD 방식으로 진행합니다:

1. **Red**: 실패하는 테스트를 먼저 작성
2. **Green**: 테스트를 통과하는 최소한의 코드 작성
3. **Refactor**: 코드 품질 개선 (테스트는 계속 통과해야 함)

#### TDD 규칙
- 새로운 기능 추가 시 반드시 테스트 먼저 작성
- 버그 수정 시 버그를 재현하는 테스트 먼저 작성
- 리팩토링 전 기존 동작을 검증하는 테스트 확인
- 테스트 없이 프로덕션 코드 수정 금지

#### 테스트 작성 가이드
- 단위 테스트: `test/` 디렉토리에 소스 구조와 동일하게 구성
- 테스트 파일명: `*_test.dart`
- Mock 객체: `test/mocks/` 디렉토리에 정의
- 테스트 커버리지 목표: 80% 이상

### 코드 품질
- `flutter analyze` 경고 없이 통과
- 린트 규칙 준수 (analysis_options.yaml)
- 코드 변경 후 관련 테스트 실행하여 검증

### 커밋 전 체크리스트
1. 테스트 작성 완료
2. `flutter test` 통과
3. `flutter analyze` 통과
4. 코드 리뷰 가능한 상태

## Project Structure
- `lib/`: 소스 코드
  - `core/`: 공통 유틸리티, 상수, 네트워크
  - `data/`: 데이터 계층 (모델, 데이터소스, 리포지토리 구현)
  - `domain/`: 도메인 계층 (엔티티, 리포지토리 인터페이스)
  - `presentation/`: UI 계층 (페이지, BLoC, 위젯)
- `test/`: 테스트 코드

## Tech Stack
- Flutter with BLoC pattern
- Injectable for DI
- Dio for HTTP
- STOMP WebSocket for real-time messaging
- Firebase Cloud Messaging (FCM) for push notifications (Android only)
- Flutter Local Notifications for local notifications

## Pending Tasks

### iOS 푸시 알림 활성화 (Apple Developer 유료 가입 필요)

현재 FCM 푸시 알림은 **Android만 지원**합니다. iOS 푸시 알림을 활성화하려면:

#### 1. Apple Developer Program 가입 ($99/년)
- https://developer.apple.com/programs/enroll/

#### 2. Xcode 설정
- Signing & Capabilities > **Push Notifications** 추가
- Signing & Capabilities > **Background Modes** > Remote notifications 체크

#### 3. APNs 키 발급
- Apple Developer > Certificates, Identifiers & Profiles > Keys
- 새 키 생성 > Apple Push Notifications service (APNs) 체크
- `.p8` 파일 다운로드 (한 번만 가능, 잘 보관)

#### 4. Firebase Console 설정
- 프로젝트 설정 > 클라우드 메시징 > Apple 앱 구성
- APNs 인증 키 (.p8 파일) 업로드
- Key ID, Team ID 입력

#### 5. 코드 수정 (TODO 검색)
다음 파일들에서 `TODO: iOS` 검색 후 `Platform.isIOS` 조건 추가:
- `lib/main.dart`
- `lib/core/services/fcm_service.dart`
- `lib/presentation/blocs/auth/auth_bloc.dart`
