## 개요
에러 핸들링 및 아키텍처 개선

## 목표
- WebSocketPayloadParser 의존성 주입 수정
- 데이터 레이어 에러 핸들링 개선
- BLoC 레이어 에러 핸들링 및 상태 관리 개선
- UI 페이지 개선
- 테스트 커버리지 향상

## 주요 변경사항

### 의존성 주입 수정
- WebSocketPayloadParser에 @singleton 어노테이션 추가
- GetIt에 WebSocketPayloadParser 등록하여 의존성 주입 오류 해결

### 데이터 레이어 개선
- Remote DataSource 에러 핸들링 개선
- Repository 구현 개선
- 데이터 모델 업데이트

### 도메인 레이어 개선
- 엔티티 필드 추가/수정
- Repository 인터페이스 개선

### BLoC 레이어 개선
- AuthBloc 에러 핸들링 개선
- ChatListBloc 에러 핸들링 개선
- ChatRoomBloc 에러 핸들링 및 상태 관리 개선
- FriendBloc 에러 핸들링 개선
- Event 및 State 개선

### UI 페이지 개선
- ChatListPage UI 및 에러 핸들링 개선
- ChatRoomPage UI 및 에러 핸들링 개선
- FriendListPage 개선
- ProfilePage 개선
- EditProfilePage 추가

### 테스트 코드 추가/개선
- ChatRoomBloc 테스트 추가
- ChatRoomPage 테스트 개선
- FriendListPage 테스트 개선
- Mock 엔티티 추가

## 통계
- 변경 파일: 41개
- 추가: 2,917줄 / 삭제: 214줄
- 커밋: 8개 (논리적 단위로 분리)

## 체크리스트
- [ ] 코드 리뷰 준비 완료
- [ ] 테스트 통과
- [ ] 문서 업데이트 완료
