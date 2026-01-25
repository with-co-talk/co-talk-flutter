# 📋 에러 처리 개선

## 🎯 목표
코드 리뷰 피드백을 반영하여 에러 처리의 일관성과 사용자 경험을 개선합니다.

## ✨ 주요 변경사항

### 에러 처리 유틸리티 추가
- ✅ `ErrorMessageMapper`: Exception을 사용자 친화적인 메시지로 변환
- ✅ `ExceptionToFailureMapper`: Exception을 Failure로 변환
- ✅ 에러 타입별 적절한 메시지 매핑 로직 구현

### 에러 페이지 추가
- ✅ `ErrorPage` 위젯 구현
- ✅ 라우팅 에러 시 사용자 친화적인 에러 화면 제공

### 에러 처리 로직 개선
- ✅ AuthBloc: 사용자 친화적인 에러 메시지 제공
- ✅ AuthRepository: Exception을 Failure로 변환하여 명시적 에러 처리
- ✅ AuthInterceptor: 순환 참조 해결 및 토큰 갱신 로직 개선
- ✅ Router: null 체크 및 에러 페이지 표시
- ✅ LocalDataSource: 잘못된 형식 데이터 감지 및 처리

## 🔍 개선 사항

### Before
- `e.toString()` 사용으로 사용자에게 불명확한 메시지 제공
- Exception을 무시하고 null 반환
- 순환 참조 위험
- null 안전성 부족

### After
- 사용자 친화적인 에러 메시지 제공
- 명시적 Failure throw
- 순환 참조 해결
- 강화된 null 안전성
