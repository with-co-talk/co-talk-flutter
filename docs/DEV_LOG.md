# Co-Talk Flutter 개발 로그

개발자 블로그처럼, 최근에 손댄 기능과 결정을 정리한 문서입니다.

---

## 2026년 2월: 채팅 UX·알림·URL 개선

### 1. 채팅방 사진을 갤러리에 저장하기

**하고 싶었던 것**  
채팅으로 받은 사진을 기기 갤러리(사진 앱)에 저장하고 싶다.

**한 일**

- **gal** 패키지로 Android/iOS에서 갤러리 저장. 웹은 지원 안 하므로 저장 버튼/메뉴를 숨김.
- **저장 경로**: URL에서 이미지 바이트를 받아 `Gal.putImageBytes()`로 저장. 상대 URL이면 `ApiConstants.baseUrl`을 붙여서 사용.
- **진입점**  
  - 전체 화면 보기 화면 AppBar에 "갤러리에 저장" 버튼  
  - 채팅 이미지 **길게 누르기** → "전체 화면 보기" / "갤러리에 저장" 바텀시트
- **권한**: iOS에 `NSPhotoLibraryAddUsageDescription` 추가. Android는 기존 저장 권한 사용.

**파일**

- `lib/core/utils/save_image_to_gallery.dart` — URL → 다운로드 → 갤러리 저장
- `lib/presentation/pages/chat/chat_room_page.dart` — 전체 화면 저장 버튼, 이미지 길게 누르기 메뉴

**정리**  
한 번에 “저장 유틸 + 진입점 두 가지(전체화면 버튼, 길게 누르기)”로 마무리해서, 사용자가 원하는 방식으로 저장할 수 있게 했다.

---

### 2. "이게 URL이다"를 더 넓게 인식하기

**하고 싶었던 것**  
`https://` 없이 `naver.com`, `www.naver.com`만 쳐도 링크로 인식하고, 열 때·미리보기 API 호출할 때는 `https://`를 붙여서 쓰고 싶다.

**기존**  
`http(s)://`로 시작하는 문자열만 URL로 보고, 그대로 클릭/API에 사용.

**한 일**

- **감지**  
  - `https?://` 로 시작하는 문자열  
  - `www.` 로 시작하는 문자열  
  - `xxx.com`, `xxx.co.kr`, `xxx.net` 등 **도메인 패턴** (일반 TLD 포함)  
  → 한 개의 정규식 `urlPattern`으로 매칭.
- **정규화**  
  - 끝의 `.,;:!?` 등 구두점 제거  
  - `http://` / `https://` 가 없으면 앞에 `https://` 붙이기 (`normalizeUrl()`).
- **적용**  
  - 채팅 메시지: **표시**는 매칭된 문자열 그대로, **클릭·미리보기 API**에는 `normalizeUrl()` 결과만 사용.

**파일**

- `lib/core/utils/url_utils.dart` — `urlPattern`, `normalizeUrl()`
- `lib/presentation/pages/chat/chat_room_page.dart` — URL 스팬 생성·클릭·첫 URL 미리보기에 `url_utils` 사용

**정리**  
“URL인지 판별”과 “실제로 쓸 URL 문자열 만들기”를 한 곳(`url_utils`)에서 하니까, 채팅 표시·외부 브라우저·미리보기 API가 같은 규칙을 쓰게 됐다.

---

### 3. 푸시(알림)에 앱 아이콘 보이게 하기

**하고 싶었던 것**  
푸시 알림에 Flutter 기본 아이콘 대신 Co-Talk 앱 아이콘이 보이게 하고 싶다.

**플랫폼별**

- **Android**  
  - `AndroidNotificationDetails`에 `icon: '@mipmap/ic_launcher'` 지정.  
  - FCM 포그라운드·데스크톱 WebSocket 알림 모두 같은 `NotificationService`를 쓰므로 둘 다 앱 아이콘 사용.
- **iOS / macOS / Windows**  
  - 플러그인에서 “알림 전용 아이콘”을 따로 지정하는 옵션이 없고, **앱 번들 아이콘**이 그대로 쓰인다.  
  - 그래서 “알림에 Flutter 기본 아이콘이 보인다” = “앱 아이콘이 아직 기본”이라는 뜻.
- **해결**  
  - `assets/icons/app_icon.png`를 Co-Talk 아이콘으로 두고  
  - `dart run flutter_launcher_icons` 로 모든 플랫폼 앱 아이콘 재생성  
  - 이후 앱 다시 빌드·실행.

**문서**

- README에 "알림(푸시) 아이콘 (iOS / macOS / Windows)" 섹션 추가
- `NotificationService` 초기화 주석에 “알림 아이콘 = 앱 아이콘, 재생성 방법” 안내

**정리**  
Android는 코드로 알림 아이콘을 지정했고, iOS/macOS/Windows는 “앱 아이콘을 Co-Talk으로 바꾸면 알림도 따라간다”는 걸 문서로 명확히 했다.

---

## 문서·프로젝트 정리

- **CHANGELOG.md**  
  - 위 변경들을 Added/Changed/Documentation 기준으로 나열.  
  - [Unreleased] / [1.0.0] 구분.
- **README.md**  
  - 알림 아이콘 섹션, 필요 시 다른 최신 기능 설명 반영.  
  - 변경 이력·개발 로그는 CHANGELOG·DEV_LOG 링크로 안내.
- **이 문서 (docs/DEV_LOG.md)**  
  - “왜 이렇게 했는지”, “무엇을 바꿨는지”를 개발자 블로그처럼 읽을 수 있게 정리.

추가로 기능이 들어오거나 결정이 바뀌면, 여기에 날짜/제목 단위로 블로그 포스트처럼 이어서 적으면 된다.
