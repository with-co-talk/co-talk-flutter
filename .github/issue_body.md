# 에러 처리 및 API 응답 형식 처리 개선

## 🎯 목표
- API 응답 형식 불일치 문제 해결
- 에러 처리 로직 개선 및 중복 코드 제거
- UI 버그 수정 및 사용자 경험 개선

## 📋 주요 변경사항

### 1. 공통 유틸리티 추가
- **BaseRemoteDataSource**: 모든 Remote DataSource의 공통 기능 제공
  - 공통 에러 처리 로직 (`handleDioError`)
  - 리스트 추출 로직 (`extractListFromResponse`)
- **DateParser**: 서버의 다양한 날짜 형식 파싱 지원
  - ISO 8601 문자열 형식
  - Java LocalDateTime 배열 형식 `[2026,1,22,3,4,10,946596000]`

### 2. 에러 처리 개선
- **AuthInterceptor**: `Interceptor` → `QueuedInterceptor`로 변경
  - async 메서드 안전하게 처리
  - Auth 엔드포인트에서 토큰 갱신 로직 제외
- **Bloc 에러 처리**: `e.toString()` 대신 Exception의 `message` 필드 사용
  - FriendBloc, ChatListBloc 에러 메시지 추출 개선

### 3. API 응답 형식 처리
- **친구 목록**: 평면 구조 응답을 중첩 구조로 변환
- **채팅방 목록**: `rooms` 키에서 리스트 추출
- **메시지 전송**: `messageId` → `id` 변환, `createdAt` 배열 형식 처리

### 4. UI 버그 수정
- **친구 목록**: TextEditingController dispose 문제 해결
- **친구 목록**: 대화하기 버튼 기능 구현
- **채팅 목록**: 에러 발생 시 SnackBar 표시
- **main.dart**: intl 패키지 한국어 로케일 초기화

### 5. 테스트 수정
- FriendBloc 테스트를 실제 구현에 맞게 수정
  - FriendRequestAccepted: getReceivedFriendRequests 호출 확인
  - FriendRequestRejected: receivedRequests 업데이트 확인

## ✅ 체크리스트
- [x] BaseRemoteDataSource 추가
- [x] DateParser 유틸리티 추가
- [x] AuthInterceptor 개선
- [x] API 응답 형식 처리 개선
- [x] UI 버그 수정
- [x] 테스트 수정
- [x] 에러 메시지 추출 개선
