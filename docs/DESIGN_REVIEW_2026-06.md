# Co-Talk Flutter — 디자인 & 인터랙션 품질 리뷰 (2026-06-08)

frontend-design 기준(독창성·정제된 완성도·제네릭 룩 회피) + 모던 메신저(KakaoTalk/iMessage/Telegram) 대비.
5개 영역(Onboarding/Auth, Chat, Friends, Profile/Cropper, Settings) 병렬 리뷰 종합.

---

## 한 줄 결론
아키텍처(BLoC)·색상 토큰·다크모드 설계는 단단하지만, **인터랙션 레이어가 거의 비어 있어** "기본 Material 데모"처럼 보인다.
시각 리디자인보다 **모션/마이크로인터랙션 + 테마 2곳** 손보는 게 핵심. 대부분 고치기 쉬운 항목.

---

## 근본 원인 3가지 (모든 영역에서 반복 지적됨)

### 1. 라이트모드 AppBar가 보라색 꽉 찬 바 (M2 패턴)
- `core/theme/app_theme.dart:20` — `appBarTheme.backgroundColor: AppColors.primary`
- 5개 영역 전부에서 "가장 강한 촌스러움 신호"로 지목. `useMaterial3: true`인데 M2 룩.
- **한 줄 수정으로 전 화면 동시 개선**: surface 배경 + textPrimary 전경.

### 2. 타이포그래피 정체성 0 — 시스템 Roboto 의존
- `app_theme.dart`에 `textTheme` 정의 없음, `google_fonts` 미사용.
- 화면마다 `fontSize: 14/16/18` 매직넘버 직박음.
- **Pretendard / Noto Sans KR** 적용 시 100% 텍스트 품질 상승 (한 줄).

### 3. 모션 언어 부재 = "안 매끄럽다"의 정체
- 전체 화면 중 애니메이션 사용 파일 6개뿐. **라우터에 커스텀 전환 0개**.
- 리스트가 `ListView.builder` (AnimatedList 아님) → 새 항목이 툭 나타남.
- 로딩이 전부 맨 `CircularProgressIndicator` → shimmer 스켈레톤 없음.
- **햅틱(HapticFeedback) 전무**. 에러는 전부 기본 SnackBar.

---

## 영역별 핵심 (🔴 = 우선순위 높음)

### Chat (제품의 심장 — 가장 시급)
- 🔴 채팅방 AppBar 제목이 **하드코딩 "채팅"** — 상대 이름/아바타/온라인 없음. `chat_room_page.dart:495`. "미완성" 최대 신호.
- 🔴 **발신자 그룹핑 없음** — 연속 메시지마다 아바타+닉네임 반복. `message_bubble.dart:1148`. 대화가 폼처럼 보임.
- 🔴 **버블 진입 애니메이션 없음** + `ListView.builder` — 새 메시지가 툭 뜸. `message_list.dart:59`. "안 매끄럽다" 핵심.
- 🔴 **타이핑 인디케이터가 이탤릭 텍스트** — 애니메이션 점 3개 아님. `message_list.dart:85`. 디버그 라벨처럼 보임.
- 🔴 전송 버튼 상태 전환 즉시 스냅 + 전송 시 햅틱 없음. `message_input.dart:651`.
- 🟡 이미지/영상 풀스크린에 Hero 전환 없음 / scroll FAB threshold 100px로 과민 / 날짜 구분선 단색 박스.

### Onboarding & Auth
- 🔴 스플래시 로고/워드마크 진입 애니메이션 0, 스톡 아이콘(`Icons.chat_bubble_rounded`)을 로고로 사용.
- 🔴 로그인/회원가입 에러가 전부 **빨간 기본 SnackBar** — 인라인 배너로 교체 권장.
- 🔴 이메일 인증 화면 정지 아이콘 — 대기 상태인데 모션 0 → 멈춘 느낌.
- 🟡 회원가입에 브랜딩 0(설정 페이지처럼 보임), `arrow_back` iOS에서 어색, `Colors.orange[700]` 하드코딩.

### Friends
- 🔴 친구 추가/수락/차단/삭제 시 **리스트 exit 애니메이션 0** — 항목이 즉시 사라짐.
- 🔴 로딩이 맨 스피너 → shimmer 스켈레톤 필요.
- 🟡 모든 아바타가 동일 보라 — 이름 해시 기반 색상으로 개성화 / 차단·숨김 유저는 그레이스케일 처리 / 수락·거절 버튼 오버플로 위험.

### Profile & 이미지 크롭퍼 ⭐ (당신이 직접 지적한 부분)
- 🔴 **결정적 원인: 프로필 크롭퍼가 OS 기본 크롭 UI 사용** — `image_cropper_handler.dart:14,35`에서 `uiSettings` 미전달 → 안드로이드 uCrop(teal)/iOS 기본 파란 UI 그대로 노출. 이게 "크롭퍼가 촌스럽다"의 직접 기계적 원인.
- 🟢 **이미 `pro_image_editor` 패키지가 설치돼 있고 앱 테마로 커스텀까지 돼 있음** — 그런데 채팅에서만 씀. 프로필도 이걸로 라우팅하면 **새 의존성 0으로 해결**.
- 🔴 프로필 아바타/배경 선택 시 크롭 단계 자체를 건너뛰고 원본 업로드되는 경로 존재. `profile_view_page.dart:640`.
- 🔴 프로필 이미지가 `Image.network()` → 열 때마다 회색 깜빡임. `CachedNetworkImage`+`Shimmer`(둘 다 이미 설치됨)로.
- 🟡 form 필드·바텀시트에 `Colors.grey[*]`/`Colors.white` 하드코딩 다수 → 다크모드에서 흰 박스.

### Settings
- 🔴 **플랫 ListTile 벽** — 섹션 그룹핑 카드 없음. `settings_page.dart:253`. 안드로이드 4 시절 설정 룩. → 섹션을 둥근 Card로 묶으면 7개 화면 동시 개선.
- 🔴 비밀번호 변경 요구사항 체크리스트가 **항상 정적**(입력해도 체크 안 됨). `change_password_page.dart:221`.
- 🔴 회원탈퇴 카운트다운 텍스트만 / 약관·개인정보 raw 텍스트 덤프 / `Colors.green·red` 하드코딩 다수.

---

## 전역 우선순위 (Impact ÷ Effort)

| # | 작업 | 효과 | 비용 | 파일 |
|---|------|------|------|------|
| 1 | AppBar surface 배경으로 전환 | 전 화면 즉시 현대화 | 한 줄 | `app_theme.dart:20` |
| 2 | 커스텀 TextTheme (Pretendard) | 전 텍스트 품질↑ | 한 줄 | `app_theme.dart` |
| 3 | 프로필 크롭퍼 → `pro_image_editor`로 교체 | 크롭 체감 해결 | 소 | `image_cropper_handler.dart` |
| 4 | 로딩 전부 shimmer 스켈레톤 | "안 매끄럽다" 핵심 | 중 | chat/friends 리스트 |
| 5 | 채팅 버블 그룹핑 + AnimatedList 진입 | 채팅 현대화 | 중 | `message_bubble/list` |
| 6 | 채팅방 AppBar에 상대 이름+아바타 | "미완성" 신호 제거 | 소 | `chat_room_page.dart` |
| 7 | 타이핑 인디케이터 점3개 애니메이션 | 모던 메신저 시그널 | 소 | `message_list.dart` |
| 8 | 햅틱(전송/롱프레스/토글/스와이프) | 마이크로 만족감 | 소 | 전역 |
| 9 | `AppSpacing`/`AppRadius` 토큰 + 매직넘버 치환 | 일관성 | 중 | 신규 토큰 파일 |
| 10 | 하드코딩 `Colors.*` → 토큰 / 에러 SnackBar → 인라인 배너 | 다크모드 안정 | 중 | 전역 |

> ⚠️ 이 프로젝트는 CLAUDE.md에 **TDD 필수** + `flutter analyze` 무경고 규칙이 있어, 위젯 변경 시 위젯/골든 테스트 동반 필요.
