# 📋 에러 처리 개선

## 🎯 개요
코드 리뷰 피드백을 반영하여 에러 처리의 일관성과 사용자 경험을 개선합니다.

## ✨ 주요 변경사항

### 에러 처리 유틸리티 추가
- ✅ `ErrorMessageMapper`: Exception을 사용자 친화적인 메시지로 변환
  - AuthException, ServerException, NetworkException 등 타입별 메시지 매핑
  - HTTP 상태 코드별 적절한 메시지 제공
- ✅ `ExceptionToFailureMapper`: Exception을 Failure로 변환
  - Domain 레이어로 에러 전달 시 일관된 형식 유지

### 에러 페이지 추가
- ✅ `ErrorPage` 위젯 구현
- ✅ 라우팅 에러 시 사용자 친화적인 에러 화면 제공
- ✅ 홈으로 돌아가기 기능 포함

### 에러 처리 로직 개선

#### AuthBloc
- ✅ `ErrorMessageMapper`를 사용하여 사용자 친화적인 에러 메시지 제공
- ✅ `e.toString()` 대신 명확한 에러 메시지 반환
- ✅ 모든 catch 블록에서 일관된 에러 처리 적용

#### AuthRepository
- ✅ `ExceptionToFailureMapper`를 사용하여 Exception을 Failure로 변환
- ✅ `getCurrentUser()`에서 null 대신 명시적 Failure throw
- ✅ `refreshToken()`에서 적절한 AuthException throw
- ✅ 에러 처리 일관성 향상

#### AuthInterceptor
- ✅ 토큰 갱신 전용 Dio 인스턴스 생성하여 순환 참조 방지
- ✅ `AuthRemoteDataSource`를 활용한 토큰 갱신 로직 개선
- ✅ null 안전성 강화 및 에러 처리 개선

#### Router
- ✅ `roomId` 파싱 시 null 체크 및 에러 페이지 표시
- ✅ 잘못된 형식의 roomId 처리

#### LocalDataSource
- ✅ `getUserId()`에서 잘못된 형식 데이터 감지 및 처리
- ✅ try-catch로 저장소 읽기 실패 처리 강화

## 📊 통계 정보
- **변경 파일 수**: 8개
- **추가된 코드**: 115줄
- **수정된 코드**: 61줄
- **커밋 수**: 6개

## 🔍 개선 사항

### Before
- `e.toString()` 사용으로 사용자에게 불명확한 메시지 제공
- Exception을 무시하고 null 반환
- 순환 참조 위험 (AuthInterceptor)
- null 안전성 부족

### After
- 사용자 친화적인 에러 메시지 제공
- 명시적 Failure throw
- 순환 참조 해결
- 강화된 null 안전성

## 🧪 테스트 방법
```bash
# 린트 확인
flutter analyze

# 테스트 실행
flutter test

# 앱 실행하여 에러 처리 확인
flutter run
```

## 📝 리뷰 포인트
- [ ] 에러 메시지가 사용자에게 적절한지
- [ ] Exception → Failure 변환이 올바르게 동작하는지
- [ ] 순환 참조가 해결되었는지
- [ ] null 안전성이 충분한지
- [ ] 에러 페이지가 적절히 표시되는지

## 🔗 관련 이슈
Closes #3
