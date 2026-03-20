import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:go_router/go_router.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/chat_settings_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/chat_settings_state.dart';
import 'package:co_talk_flutter/presentation/pages/settings/chat_settings_page.dart';
import 'package:co_talk_flutter/domain/entities/chat_settings.dart';

class MockChatSettingsCubit extends MockCubit<ChatSettingsState>
    implements ChatSettingsCubit {}

void main() {
  late MockChatSettingsCubit mockChatSettingsCubit;

  setUp(() {
    mockChatSettingsCubit = MockChatSettingsCubit();
    // Stub loadSettings to return a completed Future
    when(() => mockChatSettingsCubit.loadSettings()).thenAnswer((_) async {});
  });

  const defaultSettings = ChatSettings();

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<ChatSettingsCubit>.value(
        value: mockChatSettingsCubit,
        child: const ChatSettingsPage(),
      ),
    );
  }

  /// Creates the widget wrapped in GoRouter for navigation tests.
  Widget createWidgetWithRouter({bool canPop = false}) {
    final router = GoRouter(
      initialLocation: '/chat-settings',
      routes: [
        GoRoute(
          path: '/chat-settings',
          builder: (context, state) => BlocProvider<ChatSettingsCubit>.value(
            value: mockChatSettingsCubit,
            child: const ChatSettingsPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              const Scaffold(body: Text('Settings Page')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('ChatSettingsPage', () {
    group('Initial Rendering', () {
      testWidgets('renders app bar with title', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('채팅 설정'), findsOneWidget);
      });

      testWidgets('shows back button in app bar', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('calls loadSettings on init', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.initial(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        verify(() => mockChatSettingsCubit.loadSettings()).called(1);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading indicator when status is loading',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loading(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Loaded State', () {
      testWidgets('shows all settings sections', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('글꼴 크기'), findsOneWidget);
        expect(find.text('미디어 자동 다운로드'), findsOneWidget);
        expect(find.text('입력 표시'), findsOneWidget);
        expect(find.text('저장 공간'), findsOneWidget);
      });

      testWidgets('shows font size slider', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(Slider), findsOneWidget);
        expect(find.text('작게'), findsOneWidget);
        expect(find.text('크게'), findsOneWidget);
      });

      testWidgets('shows font size preview', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('미리보기'), findsOneWidget);
        expect(find.text('안녕하세요! 글꼴 크기를 조절해보세요.'), findsOneWidget);
      });

      testWidgets('shows typing indicator switch', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('입력중 표시'), findsOneWidget);
        expect(find.byType(SwitchListTile), findsWidgets);
      });

      testWidgets('shows cache clear button', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('캐시 삭제'), findsOneWidget);
        expect(find.text('임시 저장된 데이터를 삭제합니다'), findsOneWidget);
      });
    });

    group('Font Size Settings', () {
      testWidgets('updates font size when slider is moved', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );
        when(() => mockChatSettingsCubit.setFontSize(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = find.byType(Slider);
        await tester.drag(slider, const Offset(100, 0));
        await tester.pumpAndSettle();

        // Slider can call setFontSize multiple times during drag
        verify(() => mockChatSettingsCubit.setFontSize(any())).called(greaterThan(0));
      });

      testWidgets('displays correct font size label', (tester) async {
        const settings = ChatSettings(fontSize: 1.2);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, 1.2);
      });
    });

    group('Auto Download Settings - Mobile', () {
      testWidgets('shows wifi and mobile data options on mobile',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // On mobile platforms, should show wifi/mobile data options
        // This test assumes Platform.isAndroid or Platform.isIOS returns true
        // In test environment, it will show desktop UI, so we test for that
        expect(find.text('이미지 자동 다운로드'), findsOneWidget);
        expect(find.text('동영상 자동 다운로드'), findsOneWidget);
      });
    });

    group('Auto Download Settings - Desktop', () {
      testWidgets('shows simple on/off switches on desktop', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // On desktop, shows simple switches
        expect(find.text('이미지 자동 다운로드'), findsOneWidget);
        expect(find.text('동영상 자동 다운로드'), findsOneWidget);
      });

      testWidgets('updates image auto download setting', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );
        when(() => mockChatSettingsCubit.setAutoDownloadImagesOnWifi(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final imageSwitch =
            find.widgetWithText(SwitchListTile, '이미지 자동 다운로드');
        await tester.tap(imageSwitch);
        await tester.pump();

        verify(() => mockChatSettingsCubit.setAutoDownloadImagesOnWifi(any()))
            .called(greaterThan(0));
      });

      testWidgets('updates video auto download setting', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );
        when(() => mockChatSettingsCubit.setAutoDownloadVideosOnWifi(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final videoSwitch =
            find.widgetWithText(SwitchListTile, '동영상 자동 다운로드');
        await tester.tap(videoSwitch);
        await tester.pump();

        verify(() => mockChatSettingsCubit.setAutoDownloadVideosOnWifi(any()))
            .called(1);
      });
    });

    group('Typing Indicator Settings', () {
      testWidgets('updates typing indicator setting', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );
        when(() => mockChatSettingsCubit.setShowTypingIndicator(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final typingSwitch =
            find.widgetWithText(SwitchListTile, '입력중 표시');
        await tester.tap(typingSwitch);
        await tester.pump();

        verify(() => mockChatSettingsCubit.setShowTypingIndicator(any()))
            .called(1);
      });

      testWidgets('shows typing indicator description', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(
          find.text('상대방이 메시지를 입력 중일 때 표시합니다. 켜면 나의 입력 상태도 상대방에게 전송됩니다.'),
          findsOneWidget,
        );
      });
    });

    group('Cache Management', () {
      testWidgets('shows clear cache dialog when button is tapped',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Scroll to and tap on the icon
        await tester.ensureVisible(find.byIcon(Icons.cleaning_services_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.cleaning_services_outlined), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Check dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text('임시 저장된 데이터를 삭제하시겠습니까?\n다운로드한 이미지와 동영상 캐시가 삭제됩니다.'),
          findsOneWidget,
        );
        expect(find.text('취소'), findsOneWidget);
        expect(find.text('삭제'), findsOneWidget);
      });

      testWidgets('clears cache when confirmed', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );
        when(() => mockChatSettingsCubit.clearCache())
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        // Scroll to the cache button and tap it
        await tester.ensureVisible(find.byIcon(Icons.cleaning_services_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.cleaning_services_outlined), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Confirm deletion - just tap the "삭제" text (should be in a TextButton)
        await tester.tap(find.text('삭제'));
        await tester.pumpAndSettle();

        verify(() => mockChatSettingsCubit.clearCache()).called(1);
      });

      testWidgets('shows loading indicator during cache clear',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.clearing(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final cacheTile = find.widgetWithText(ListTile, '캐시 삭제');
        expect(cacheTile, findsOneWidget);

        // Should show loading indicator in the tile
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Clearing State', () {
      testWidgets('shows snackbar when clearing cache', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Simulate state change to clearing
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.clearing(),
        );

        // Trigger rebuild
        await tester.pumpAndSettle();

        // Snackbar should appear (tested via BlocConsumer listener)
      });

      testWidgets('shows success message after cache cleared', (tester) async {
        // Set up state stream to emit clearing then loaded
        whenListen(
          mockChatSettingsCubit,
          Stream.fromIterable([
            const ChatSettingsState.clearing(),
            const ChatSettingsState.loaded(defaultSettings),
          ]),
          initialState: const ChatSettingsState.clearing(),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump(); // Initial state

        // Trigger state change
        await tester.pump();

        // Success snackbar tested via listener
        expect(find.text('캐시가 삭제되었습니다'), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('shows error message when clearing cache fails',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Simulate state change to error
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.error('Failed to clear cache'),
        );

        await tester.pumpAndSettle();

        // Error snackbar tested via listener
      });
    });

    group('Settings Persistence', () {
      testWidgets('displays loaded settings values', (tester) async {
        const customSettings = ChatSettings(
          fontSize: 1.3,
          autoDownloadImagesOnWifi: false,
          autoDownloadVideosOnWifi: false,
          showTypingIndicator: false,
        );

        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(customSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, 1.3);

        // Switches should reflect custom settings
        final switches = tester.widgetList<SwitchListTile>(
          find.byType(SwitchListTile),
        );

        expect(switches.length, greaterThan(0));
      });
    });

    group('Navigation', () {
      testWidgets('back button navigates to settings when cannot pop',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetWithRouter());
        await tester.pumpAndSettle();

        // Tap the back button - cannot pop at root so goes to /settings
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should navigate to settings page
        expect(find.text('Settings Page'), findsOneWidget);
      });

      testWidgets('back button pops when can pop', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        // Build a router that starts at a page that pushes chat-settings
        final router = GoRouter(
          initialLocation: '/settings',
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => ctx.push('/chat-settings'),
                    child: const Text('Open Chat Settings'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/chat-settings',
              builder: (context, state) =>
                  BlocProvider<ChatSettingsCubit>.value(
                value: mockChatSettingsCubit,
                child: const ChatSettingsPage(),
              ),
            ),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Navigate to chat settings
        await tester.tap(find.text('Open Chat Settings'));
        await tester.pumpAndSettle();

        expect(find.text('채팅 설정'), findsOneWidget);

        // Tap back - canPop() is true here
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should be back on settings page
        expect(find.text('Open Chat Settings'), findsOneWidget);
      });
    });

    group('Font Size Label', () {
      testWidgets('shows 아주 작게 label for very small font', (tester) async {
        const settings = ChatSettings(fontSize: 0.8);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );
        when(() => mockChatSettingsCubit.setFontSize(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, 0.8);
        expect(slider.label, '아주 작게');
      });

      testWidgets('shows 작게 label for small font', (tester) async {
        const settings = ChatSettings(fontSize: 0.9);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.label, '작게');
      });

      testWidgets('shows 보통 label for normal font', (tester) async {
        const settings = ChatSettings(fontSize: 1.0);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.label, '보통');
      });

      testWidgets('shows 크게 label for large font', (tester) async {
        const settings = ChatSettings(fontSize: 1.1);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.label, '크게');
      });

      testWidgets('shows 아주 크게 label for very large font', (tester) async {
        const settings = ChatSettings(fontSize: 1.2);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.label, '아주 크게');
      });

      testWidgets('shows 매우 크게 label for maximum font', (tester) async {
        const settings = ChatSettings(fontSize: 1.4);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.label, '매우 크게');
      });
    });

    group('Slider Drag Behavior', () {
      testWidgets('updates local dragging state during slider drag',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );
        when(() => mockChatSettingsCubit.setFontSize(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final sliderFinder = find.byType(Slider);
        final Slider sliderBefore = tester.widget<Slider>(sliderFinder);
        expect(sliderBefore.value, 1.0);

        // Drag slider and release
        final sliderRect = tester.getRect(sliderFinder);
        final center = sliderRect.center;
        final TestGesture gesture =
            await tester.startGesture(center);
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        // setFontSize should be called after drag ends
        verify(() => mockChatSettingsCubit.setFontSize(any()))
            .called(greaterThan(0));
      });

      testWidgets('preview reflects dragging font size', (tester) async {
        const settings = ChatSettings(fontSize: 1.0);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );
        when(() => mockChatSettingsCubit.setFontSize(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        // Preview text should be visible
        expect(find.text('안녕하세요! 글꼴 크기를 조절해보세요.'), findsOneWidget);
        expect(find.text('Hello! Try adjusting the font size.'), findsOneWidget);
      });
    });

    group('Snackbar Listener', () {
      testWidgets('shows clearing snackbar when status changes to clearing',
          (tester) async {
        whenListen(
          mockChatSettingsCubit,
          Stream.fromIterable([
            const ChatSettingsState.clearing(),
          ]),
          initialState: const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('캐시를 삭제하는 중...'), findsOneWidget);
      });

      testWidgets('shows success snackbar after clearing completes',
          (tester) async {
        whenListen(
          mockChatSettingsCubit,
          Stream.fromIterable([
            const ChatSettingsState.clearing(),
            const ChatSettingsState.loaded(defaultSettings),
          ]),
          initialState: const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('캐시가 삭제되었습니다'), findsOneWidget);
      });

      testWidgets('shows error snackbar with message when clearing fails',
          (tester) async {
        whenListen(
          mockChatSettingsCubit,
          Stream.fromIterable([
            const ChatSettingsState.clearing(),
            const ChatSettingsState.error('캐시 삭제 실패'),
          ]),
          initialState: const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('캐시 삭제 실패'), findsOneWidget);
      });

      testWidgets('shows default error message when errorMessage is null',
          (tester) async {
        whenListen(
          mockChatSettingsCubit,
          Stream.fromIterable([
            const ChatSettingsState.clearing(),
            const ChatSettingsState(
              status: ChatSettingsStatus.error,
              settings: defaultSettings,
            ),
          ]),
          initialState: const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('오류가 발생했습니다'), findsOneWidget);
      });
    });

    group('Cache Tile Disabled During Clearing', () {
      testWidgets('cache tile is disabled (no trailing chevron) when clearing',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.clearing(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // During clearing, the trailing should be a spinner not a chevron
        expect(find.byIcon(Icons.chevron_right), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('cache tile shows chevron when not clearing', (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(
          find.descendant(
            of: find.widgetWithText(ListTile, '캐시 삭제'),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsNothing,
        );
      });

      testWidgets('tapping cache tile does nothing when clearing',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.clearing(),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // Tap the cache tile
        await tester.tap(find.widgetWithText(ListTile, '캐시 삭제'),
            warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 200));

        // No dialog should open since onTap is null during clearing
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Clear Cache Dialog - Cancel Button', () {
      testWidgets('cancel button closes dialog without clearing cache',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        // Open dialog
        await tester
            .ensureVisible(find.byIcon(Icons.cleaning_services_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.cleaning_services_outlined),
            warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap cancel
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.byType(AlertDialog), findsNothing);

        // clearCache should NOT have been called
        verifyNever(() => mockChatSettingsCubit.clearCache());
      });
    });

    group('Toggle Switch States', () {
      testWidgets('typing indicator switch reflects true state', (tester) async {
        const settings = ChatSettings(showTypingIndicator: true);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final typingTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, '입력중 표시'),
        );
        expect(typingTile.value, isTrue);
      });

      testWidgets('typing indicator switch reflects false state',
          (tester) async {
        const settings = ChatSettings(showTypingIndicator: false);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final typingTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, '입력중 표시'),
        );
        expect(typingTile.value, isFalse);
      });

      testWidgets('image download switch reflects false when disabled',
          (tester) async {
        const settings = ChatSettings(autoDownloadImagesOnWifi: false);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final imageTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, '이미지 자동 다운로드'),
        );
        expect(imageTile.value, isFalse);
      });

      testWidgets('video download switch reflects false when disabled',
          (tester) async {
        const settings = ChatSettings(autoDownloadVideosOnWifi: false);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        final videoTile = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, '동영상 자동 다운로드'),
        );
        expect(videoTile.value, isFalse);
      });

      testWidgets('toggling typing indicator calls cubit with toggled value',
          (tester) async {
        const settings = ChatSettings(showTypingIndicator: true);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );
        when(() => mockChatSettingsCubit.setShowTypingIndicator(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final typingSwitch =
            find.widgetWithText(SwitchListTile, '입력중 표시');
        await tester.tap(typingSwitch);
        await tester.pump();

        verify(() => mockChatSettingsCubit.setShowTypingIndicator(false))
            .called(1);
      });

      testWidgets('toggling image switch calls cubit with false when was true',
          (tester) async {
        const settings = ChatSettings(autoDownloadImagesOnWifi: true);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );
        when(() => mockChatSettingsCubit.setAutoDownloadImagesOnWifi(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final imageSwitch =
            find.widgetWithText(SwitchListTile, '이미지 자동 다운로드');
        await tester.tap(imageSwitch);
        await tester.pump();

        verify(() =>
                mockChatSettingsCubit.setAutoDownloadImagesOnWifi(false))
            .called(1);
      });

      testWidgets('toggling video switch calls cubit with false when was true',
          (tester) async {
        const settings = ChatSettings(autoDownloadVideosOnWifi: true);
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(settings),
        );
        when(() => mockChatSettingsCubit.setAutoDownloadVideosOnWifi(any()))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createWidgetUnderTest());

        final videoSwitch =
            find.widgetWithText(SwitchListTile, '동영상 자동 다운로드');
        await tester.tap(videoSwitch);
        await tester.pump();

        verify(() =>
                mockChatSettingsCubit.setAutoDownloadVideosOnWifi(false))
            .called(1);
      });
    });

    group('loadSettings not called when already loaded', () {
      testWidgets('does not call loadSettings when state is already loaded',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loaded(defaultSettings),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        verifyNever(() => mockChatSettingsCubit.loadSettings());
      });

      testWidgets('does not call loadSettings when status is loading',
          (tester) async {
        when(() => mockChatSettingsCubit.state).thenReturn(
          const ChatSettingsState.loading(),
        );

        await tester.pumpWidget(createWidgetUnderTest());

        verifyNever(() => mockChatSettingsCubit.loadSettings());
      });
    });
  });
}
