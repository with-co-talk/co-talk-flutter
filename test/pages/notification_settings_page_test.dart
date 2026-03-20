import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/notification_settings_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/notification_settings_state.dart';
import 'package:co_talk_flutter/presentation/pages/settings/notification_settings_page.dart';
import 'package:co_talk_flutter/domain/entities/notification_settings.dart';

class MockNotificationSettingsCubit extends MockCubit<NotificationSettingsState>
    implements NotificationSettingsCubit {}

void main() {
  late MockNotificationSettingsCubit mockCubit;

  setUpAll(() {
    registerFallbackValue(NotificationPreviewMode.nameAndMessage);
  });

  setUp(() {
    mockCubit = MockNotificationSettingsCubit();
    // Stub all async methods to avoid MissingStubError
    when(() => mockCubit.loadSettings()).thenAnswer((_) async {});
    when(() => mockCubit.setMessageNotification(any())).thenAnswer((_) async {});
    when(() => mockCubit.setFriendRequestNotification(any())).thenAnswer((_) async {});
    when(() => mockCubit.setGroupInviteNotification(any())).thenAnswer((_) async {});
    when(() => mockCubit.setNotificationPreviewMode(any())).thenAnswer((_) async {});
    when(() => mockCubit.setSoundEnabled(any())).thenAnswer((_) async {});
    when(() => mockCubit.setVibrationEnabled(any())).thenAnswer((_) async {});
    when(
      () => mockCubit.setDoNotDisturb(
        enabled: any(named: 'enabled'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
      ),
    ).thenAnswer((_) async {});
  });

  const loadedSettings = NotificationSettings(
    messageNotification: true,
    friendRequestNotification: true,
    groupInviteNotification: false,
    notificationPreviewMode: NotificationPreviewMode.nameAndMessage,
    soundEnabled: true,
    vibrationEnabled: false,
    doNotDisturbEnabled: false,
  );

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<NotificationSettingsCubit>.value(
        value: mockCubit,
        child: const NotificationSettingsPage(),
      ),
    );
  }

  group('NotificationSettingsPage', () {
    testWidgets('shows loading indicator when status is loading', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loading(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders app bar with 알림 설정 title', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('알림 설정'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows 알림 유형 section header', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('알림 유형'), findsOneWidget);
    });

    testWidgets('shows 알림 방식 section header', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('알림 방식'), findsOneWidget);
    });

    testWidgets('shows 방해 금지 section header after scrolling', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.scrollUntilVisible(
        find.text('방해 금지'),
        100,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('방해 금지'), findsOneWidget);
    });

    testWidgets('shows message notification toggle with correct initial value', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('메시지 알림'), findsOneWidget);
      expect(find.text('새 메시지를 받을 때 알림'), findsOneWidget);

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      // messageNotification is true → first switch should be on
      expect(switches.first.value, isTrue);
    });

    testWidgets('shows friend request notification toggle', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('친구 요청 알림'), findsOneWidget);
      expect(find.text('새 친구 요청을 받을 때 알림'), findsOneWidget);
    });

    testWidgets('shows group invite notification toggle', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('그룹 초대 알림'), findsOneWidget);
      expect(find.text('그룹 채팅에 초대받을 때 알림'), findsOneWidget);
    });

    testWidgets('shows sound toggle', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('소리'), findsOneWidget);
      expect(find.text('알림 소리 재생'), findsOneWidget);
    });

    testWidgets('shows do not disturb toggle', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.scrollUntilVisible(
        find.text('방해 금지 모드'),
        100,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('방해 금지 모드'), findsOneWidget);
      expect(find.text('설정된 시간 동안 알림 무음'), findsOneWidget);
    });

    testWidgets('shows notification preview mode section', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('알림 미리보기'), findsOneWidget);
      expect(find.text('이름 + 메시지'), findsOneWidget);
      expect(find.text('이름만'), findsOneWidget);
      expect(find.text('표시 안함'), findsOneWidget);
    });

    testWidgets('does not show DND time tiles when doNotDisturb is disabled', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('시작 시간'), findsNothing);
      expect(find.text('종료 시간'), findsNothing);
    });

    testWidgets('shows DND time tiles when doNotDisturb is enabled', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const settingsWithDnd = NotificationSettings(
        doNotDisturbEnabled: true,
        doNotDisturbStart: '22:00',
        doNotDisturbEnd: '07:00',
      );

      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(settingsWithDnd),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.scrollUntilVisible(
        find.text('시작 시간'),
        100,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('시작 시간'), findsOneWidget);
      expect(find.text('종료 시간'), findsOneWidget);
      expect(find.text('22:00'), findsOneWidget);
      expect(find.text('07:00'), findsOneWidget);
    });

    testWidgets('calls setMessageNotification when message switch toggled', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      final messageSwitch = find.ancestor(
        of: find.text('메시지 알림'),
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(messageSwitch);
      await tester.pump();

      verify(() => mockCubit.setMessageNotification(false)).called(1);
    });

    testWidgets('calls setFriendRequestNotification when friend request switch toggled', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      final friendSwitch = find.ancestor(
        of: find.text('친구 요청 알림'),
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(friendSwitch);
      await tester.pump();

      verify(() => mockCubit.setFriendRequestNotification(false)).called(1);
    });

    testWidgets('calls setSoundEnabled when sound switch toggled', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.scrollUntilVisible(
        find.text('소리'),
        100,
        scrollable: find.byType(Scrollable),
      );

      final soundSwitch = find.ancestor(
        of: find.text('소리'),
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(soundSwitch);
      await tester.pump();

      verify(() => mockCubit.setSoundEnabled(false)).called(1);
    });

    testWidgets('calls setDoNotDisturb when DND switch toggled', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.scrollUntilVisible(
        find.text('방해 금지 모드'),
        100,
        scrollable: find.byType(Scrollable),
      );

      final dndSwitch = find.ancestor(
        of: find.text('방해 금지 모드'),
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(dndSwitch);
      await tester.pump();

      verify(
        () => mockCubit.setDoNotDisturb(enabled: true),
      ).called(1);
    });

    testWidgets('calls setNotificationPreviewMode when radio option selected', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('이름만'));
      await tester.pump();

      verify(
        () => mockCubit.setNotificationPreviewMode(NotificationPreviewMode.nameOnly),
      ).called(1);
    });

    testWidgets('shows error state when status is error', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.error('설정을 불러올 수 없습니다'),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('설정을 불러올 수 없습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('calls loadSettings when retry button tapped in error state', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.error('오류 발생'),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      verify(() => mockCubit.loadSettings()).called(1);
    });

    testWidgets('shows error snackbar when error state emitted after loaded', (tester) async {
      whenListen(
        mockCubit,
        Stream.fromIterable([
          const NotificationSettingsState.loaded(loadedSettings),
          const NotificationSettingsState.error('저장 실패'),
        ]),
        initialState: const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // The error message appears in the SnackBar (listener) and possibly in the body;
      // verify the SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.descendant(of: find.byType(SnackBar), matching: find.text('저장 실패')), findsOneWidget);
    });

    testWidgets('calls loadSettings on init when status is initial', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.initial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      verify(() => mockCubit.loadSettings()).called(1);
    });

    testWidgets('does not call loadSettings on init when status is already loaded', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(loadedSettings),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      verifyNever(() => mockCubit.loadSettings());
    });

    testWidgets('nameAndMessage radio is selected when preview mode is nameAndMessage', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const NotificationSettingsState.loaded(
          NotificationSettings(
            notificationPreviewMode: NotificationPreviewMode.nameAndMessage,
          ),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      final radios = tester
          .widgetList<RadioListTile<NotificationPreviewMode>>(
            find.byType(RadioListTile<NotificationPreviewMode>),
          )
          .toList();

      expect(radios.length, 3);
      // First radio (nameAndMessage) should be selected
      expect(radios[0].groupValue, NotificationPreviewMode.nameAndMessage);
      expect(radios[0].value, NotificationPreviewMode.nameAndMessage);
    });
  });
}
