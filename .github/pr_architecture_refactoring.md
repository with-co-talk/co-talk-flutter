## 📋 개요
아키텍처 전반 리팩토링 및 Window 기능 추가

## 🎯 변경사항

### Core 레이어 개선
- WebSocket 서비스 개선
- JWT 유틸리티 추가
- 이벤트 중복 제거 캐시 추가

### 데이터 모델 개선
- ChatRoomModel 수정 및 재생성
- MessageModel 변경

### Repository 레이어 개선
- AuthRepositoryImpl 수정
- ChatRepositoryImpl 수정
- ChatRemoteDataSource 변경

### 상태 관리 개선
- ChatListBloc 수정
- ChatRoomBloc 수정
- 관련 Event 및 State 변경

### 페이지 컴포넌트 개선
- ChatListPage 수정
- ChatRoomPage 수정
- FriendListPage 수정
- MainPage 수정
- SplashPage 수정

### Theme 및 설정 개선
- AppColors 수정
- AppTheme 수정
- App 설정 변경
- DI 설정 업데이트

### Window 기능 추가 ✨
- Window 관련 유틸리티 추가 (앱 포커스 추적)

### 테스트 코드 업데이트
- Bloc 테스트 업데이트
- DataSource 테스트 업데이트
- Model 테스트 업데이트
- Page 테스트 업데이트
- Repository 테스트 업데이트

## 🔗 관련 이슈
Closes #[이슈번호]

## ✅ 체크리스트
- [x] 코드 리뷰 준비 완료
- [x] 테스트 통과
- [x] 문서 업데이트 완료

## 📝 테스트 방법
1. Core: WebSocket 연결 및 JWT 유틸리티 동작 확인
2. 데이터 모델: 모델 직렬화/역직렬화 확인
3. Repository: 데이터 소스 정상 동작 확인
4. 상태 관리: Bloc 상태 변경 정상 동작 확인
5. 페이지: UI 컴포넌트 정상 렌더링 확인
6. Window: 앱 포커스 추적 기능 확인

## 🔍 리뷰 포인트
- 아키텍처 레이어 분리 적절성
- 상태 관리 패턴 일관성
- Window 기능 구현의 확장성
- 테스트 커버리지 적절성

## 통계
- 변경 파일: 36개
- 추가: 5,485줄 / 삭제: 3,379줄
- 커밋: 9개 (논리적 단위로 분리)
