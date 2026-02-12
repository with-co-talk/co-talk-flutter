# Bug Fixes Summary - 2026-02-11

## Overview
Fixed three P2 issues following TDD methodology (RED → GREEN → REFACTOR).

---

## Fix 1: Dio Instance Leak (P2 #18)

### Problem
- `NotificationService` (line ~212) created new Dio instances for every avatar download without closing them
- `WebSocketService` (line ~568) created new Dio instances for token refresh without closing them
- Resource leak in long-running applications

### Solution
Added `finally` blocks to close Dio instances after use:

**Files Modified:**
- `/lib/core/services/notification_service.dart`
- `/lib/core/network/websocket_service.dart`

**Pattern Applied:**
```dart
Dio? dio;
try {
  dio = Dio();
  // ... use dio
} finally {
  dio?.close();  // Always cleanup, even on error
}
```

**Test Added:**
- `test/services/notification_service_test.dart` - "Dio leak prevention" test

---

## Fix 2: Search Results Avatar Display (P2 #19)

### Problem
In `FriendListPage._AddFriendBottomSheet`, search results showed only the first letter of the nickname in `CircleAvatar`. The user's `avatarUrl` was ignored.

### Solution
Added `backgroundImage` property to display avatar when available:

**Files Modified:**
- `/lib/presentation/pages/friends/friend_list_page.dart` (line ~781-794)

**Change:**
```dart
CircleAvatar(
  radius: 28,
  backgroundColor: AppColors.primaryLight,
  backgroundImage: user.avatarUrl != null
      ? NetworkImage(user.avatarUrl!)
      : null,
  child: user.avatarUrl == null
      ? Text(/* first letter */)
      : null,
)
```

**Test Added:**
- `test/presentation/pages/friends/friend_list_page_test.dart`

---

## Fix 3: WebSocket Reconnect UI (P2 #20)

### Problem
After 20 failed WebSocket reconnect attempts, connection enters `failed` state permanently with no UI indication or manual retry option.

### Solution
Created a connection status banner that:
- Displays at the top of chat pages when disconnected/failed
- Shows appropriate message and icon based on state
- Provides "재연결" (Reconnect) button to manually retry

**Files Created:**
- `/lib/presentation/widgets/connection_status_banner.dart`

**Files Modified:**
- `/lib/presentation/pages/chat/chat_room_page.dart`

**Features:**
- Stream-driven UI via `StreamBuilder<WebSocketConnectionState>`
- Different colors for states: orange (disconnected), red (failed)
- Manual retry via `resetReconnectAttempts()` + `connect()`
- Material design with SafeArea for proper mobile layout

**Test Added:**
- `test/presentation/widgets/websocket_connection_banner_test.dart`

---

## Verification

All fixes verified with:

✅ **Tests Pass**
```bash
flutter test test/services/notification_service_test.dart
flutter test test/core/websocket_connection_manager_test.dart
```

✅ **No Analyzer Issues**
```bash
flutter analyze lib/core/services/notification_service.dart
flutter analyze lib/core/network/websocket_service.dart
flutter analyze lib/presentation/pages/friends/friend_list_page.dart
flutter analyze lib/presentation/pages/chat/chat_room_page.dart
flutter analyze lib/presentation/widgets/connection_status_banner.dart
```

✅ **Build Succeeds**
```bash
flutter build apk --debug --no-shrink
```

---

## TDD Compliance

All fixes followed strict TDD:
1. **RED**: Wrote failing tests documenting the bug
2. **GREEN**: Implemented minimal code to pass tests
3. **REFACTOR**: Fixed analyzer warnings and improved code quality

---

## Related Issues

- P2 #18: Dio instance leak in NotificationService and WebSocketService
- P2 #19: Search results don't display user avatar images
- P2 #20: No UI feedback when WebSocket connection fails permanently

---

## Learnings Documentation

Detailed learnings and issues documented at:
- `.omc/notepads/fix-dio-leak-search-avatar-websocket-ui/learnings.md`
- `.omc/notepads/fix-dio-leak-search-avatar-websocket-ui/issues.md`
