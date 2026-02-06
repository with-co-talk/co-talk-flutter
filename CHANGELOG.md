# Changelog

Co-Talk Flutter 앱의 변경 이력입니다. [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 형식을 따릅니다.

## [Unreleased]

### Added

- **채팅방 사진 갤러리 저장**
  - 채팅 이미지 전체 화면 보기 화면에 "갤러리에 저장" 버튼 추가
  - 채팅 이미지 길게 누르기 시 "전체 화면 보기" / "갤러리에 저장" 메뉴 표시
  - `gal` 패키지로 Android/iOS 갤러리 저장, 웹에서는 버튼/메뉴 비표시
  - `lib/core/utils/save_image_to_gallery.dart`: URL 다운로드 후 `Gal.putImageBytes`로 저장
  - iOS: `NSPhotoLibraryAddUsageDescription` 권한 설명 추가

- **URL 감지·정규화 개선**
  - `http(s)://` 뿐 아니라 `www.xxx.xxx`, `xxx.com` 등 도메인 패턴도 URL로 인식
  - `lib/core/utils/url_utils.dart`: `urlPattern` 정규식, `normalizeUrl()` (도메인만 있으면 `https://` 접두)
  - 채팅 메시지 내 링크 클릭·미리보기 API 호출 시 정규화된 URL 사용

- **푸시 알림 아이콘**
  - Android: `AndroidNotificationDetails`에 `icon: '@mipmap/ic_launcher'` 지정
  - iOS/macOS/Windows: 알림에 앱 아이콘 사용 안내 추가 (README, `NotificationService` 주석)
  - README에 "알림(푸시) 아이콘" 섹션 및 `dart run flutter_launcher_icons` 실행 방법 정리

### Changed

- 채팅방 텍스트 메시지: URL 매칭에 `url_utils.urlPattern` 사용, 표시는 원문·클릭/API는 `normalizeUrl()` 적용
- `_openUrl`: 인자에 스킴 없으면 `normalizeUrl()` 적용 후 `launchUrl` 호출

### Documentation

- README: "알림(푸시) 아이콘 (iOS / macOS / Windows)" 섹션 추가
- `NotificationService`: 플랫폼별 알림 아이콘 동작 및 앱 아이콘 재생성 방법 주석 추가
- `docs/DEV_LOG.md`: 개발자 블로그 형식 정리 문서 추가
- 이 CHANGELOG 추가

---

## [1.0.0] (이전)

- 초기 릴리스
- 실시간 메시징, 친구/채팅방 관리, FCM·데스크톱 알림, 링크 미리보기(서버 메타 수집), 이미지/파일 전송 등
