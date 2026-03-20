# Learnings

## ChatRoomPage GetIt Widget Tests (Phase 3-2 prep)

### Pattern: Testing GetIt-injected services in widget tests
- Register stubs/mocks in GetIt via `GetIt.instance.registerSingleton<T>(stub)` in setUp
- Always check `GetIt.instance.isRegistered<T>()` before registering to avoid duplicate registration errors
- Clean up with `GetIt.instance.unregister<T>()` in tearDown (not bulk iteration — must use typed calls)

### Pattern: Stubbing non-mockable concrete classes
- `NotificationClickHandler` is a concrete class with required constructor args — use a `StubNotificationClickHandler implements NotificationClickHandler` with `noSuchMethod` override and explicit field declarations for the properties we care about
- `ActiveRoomTracker` is simple data holder — use `StubActiveRoomTracker implements ActiveRoomTracker` with `int? activeRoomId`

### Pattern: Fallback values for File in mocktail
- `any<File>()` in mocktail requires `registerFallbackValue(FakeFile())` in `setUpAll`
- `class FakeFile extends Fake implements File {}`

### Pattern: Testing try/catch guards around GetIt
- The page wraps GetIt.instance calls in try/catch; tests confirm graceful degradation when services not registered
- Use `expectLater(() async { ... }, returnsNormally)` to assert no exceptions thrown

### GetIt calls in ChatRoomPage (6 total)
1. `initState`: NotificationClickHandler — registers `onSameRoomRefresh` callback
2. `dispose`: ActiveRoomTracker — sets `activeRoomId = null`
3. `dispose`: NotificationClickHandler — clears `onSameRoomRefresh = null`
4. `_pickAndUpdateGroupImage`: ChatRepository — `uploadFile` + `updateChatRoomImage` (guarded by try/catch)
5. `build` StreamBuilder: WebSocketService — `connectionState` stream
6. `build` onReconnect: WebSocketService — `resetReconnectAttempts()` + `connect()`

### Note on _pickAndUpdateGroupImage testability
- `ImagePickerHandler` is constructed inline (not injected), so `pickFromGallery()` returns null in tests (no platform channel)
- The repository calls are never reached in widget tests; test coverage limited to: menu item exists, tap doesn't crash, and error path snackbar (when image is actually picked)
- Phase 3-2 refactoring should inject `ImagePickerHandler` to enable full testing

### Test count
- Before: 66 tests
- After: 77 tests (+11 new GetIt behavior tests)
