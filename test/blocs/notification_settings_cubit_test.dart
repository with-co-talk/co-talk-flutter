import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/notification_settings.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/notification_settings_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/notification_settings_state.dart';
import '../mocks/mock_repositories.dart';

void main() {
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    registerFallbackValue(const NotificationSettings());
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
  });

  NotificationSettingsCubit createCubit() =>
      NotificationSettingsCubit(mockSettingsRepository);

  group('NotificationSettingsCubit', () {
    test('initial state is NotificationSettingsState.initial', () {
      final cubit = createCubit();
      expect(cubit.state, const NotificationSettingsState.initial());
    });

    group('loadSettings', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'emits loading then loaded when successful',
        build: () {
          when(() => mockSettingsRepository.getNotificationSettings())
              .thenAnswer((_) async => const NotificationSettings(
                    messageNotification: false,
                    soundEnabled: false,
                  ));
          return createCubit();
        },
        act: (cubit) => cubit.loadSettings(),
        expect: () => [
          const NotificationSettingsState.loading(),
          const NotificationSettingsState.loaded(NotificationSettings(
            messageNotification: false,
            soundEnabled: false,
          )),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.getNotificationSettings()).called(1);
        },
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'emits loading then error when loading fails',
        build: () {
          when(() => mockSettingsRepository.getNotificationSettings())
              .thenThrow(Exception('Network error'));
          return createCubit();
        },
        act: (cubit) => cubit.loadSettings(),
        expect: () => [
          const NotificationSettingsState.loading(),
          isA<NotificationSettingsState>()
              .having((s) => s.status, 'status', NotificationSettingsStatus.error)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'preserves settings during loading when already loaded',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          messageNotification: false,
          soundEnabled: false,
        )),
        build: () {
          when(() => mockSettingsRepository.getNotificationSettings())
              .thenAnswer((_) async => const NotificationSettings(
                    messageNotification: false,
                    soundEnabled: false,
                  ));
          return createCubit();
        },
        act: (cubit) => cubit.loadSettings(),
        expect: () => [
          const NotificationSettingsState(
            status: NotificationSettingsStatus.loading,
            settings: NotificationSettings(
              messageNotification: false,
              soundEnabled: false,
            ),
          ),
          const NotificationSettingsState.loaded(NotificationSettings(
            messageNotification: false,
            soundEnabled: false,
          )),
        ],
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'loads default settings',
        build: () {
          when(() => mockSettingsRepository.getNotificationSettings())
              .thenAnswer((_) async => const NotificationSettings());
          return createCubit();
        },
        act: (cubit) => cubit.loadSettings(),
        verify: (cubit) {
          expect(cubit.state.settings.messageNotification, isTrue);
          expect(cubit.state.settings.friendRequestNotification, isTrue);
          expect(cubit.state.settings.groupInviteNotification, isTrue);
          expect(cubit.state.settings.soundEnabled, isTrue);
          expect(cubit.state.settings.vibrationEnabled, isTrue);
          expect(cubit.state.settings.doNotDisturbEnabled, isFalse);
        },
      );
    });

    group('setMessageNotification', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'updates messageNotification to true',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          messageNotification: false,
        )),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setMessageNotification(true),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            messageNotification: true,
          )),
        ],
        verify: (_) {
          verify(() => mockSettingsRepository.updateNotificationSettings(
                const NotificationSettings(messageNotification: true),
              )).called(1);
        },
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'rolls back on error and clears errorMessage on recovery',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          messageNotification: false,
        )),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenThrow(Exception('Update failed'));
          return createCubit();
        },
        act: (cubit) => cubit.setMessageNotification(true),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            messageNotification: true,
          )),
          isA<NotificationSettingsState>()
              .having((s) => s.status, 'status', NotificationSettingsStatus.error)
              .having((s) => s.settings.messageNotification, 'messageNotification', false),
          isA<NotificationSettingsState>()
              .having((s) => s.status, 'status', NotificationSettingsStatus.loaded)
              .having((s) => s.settings.messageNotification, 'messageNotification', false)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );
    });

    group('setFriendRequestNotification', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'updates friendRequestNotification to false',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setFriendRequestNotification(false),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            friendRequestNotification: false,
          )),
        ],
      );
    });

    group('setGroupInviteNotification', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'updates groupInviteNotification to false',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setGroupInviteNotification(false),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            groupInviteNotification: false,
          )),
        ],
      );
    });

    group('setNotificationPreviewMode', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'updates preview mode to nameOnly',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setNotificationPreviewMode(NotificationPreviewMode.nameOnly),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            notificationPreviewMode: NotificationPreviewMode.nameOnly,
          )),
        ],
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'updates preview mode to nothing',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setNotificationPreviewMode(NotificationPreviewMode.nothing),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            notificationPreviewMode: NotificationPreviewMode.nothing,
          )),
        ],
      );
    });

    group('setSoundEnabled', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'disables sound',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setSoundEnabled(false),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            soundEnabled: false,
          )),
        ],
      );
    });

    group('setVibrationEnabled', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'disables vibration',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setVibrationEnabled(false),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            vibrationEnabled: false,
          )),
        ],
      );
    });

    group('setDoNotDisturb', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'enables do not disturb mode with time range',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setDoNotDisturb(
          enabled: true,
          startTime: '22:00',
          endTime: '07:00',
        ),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            doNotDisturbEnabled: true,
            doNotDisturbStart: '22:00',
            doNotDisturbEnd: '07:00',
          )),
        ],
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'updates only enabled flag when times not provided',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          doNotDisturbStart: '22:00',
          doNotDisturbEnd: '07:00',
        )),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setDoNotDisturb(enabled: true),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            doNotDisturbEnabled: true,
            doNotDisturbStart: '22:00',
            doNotDisturbEnd: '07:00',
          )),
        ],
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'updates only time range when enabled not provided',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          doNotDisturbEnabled: true,
        )),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setDoNotDisturb(
          startTime: '23:00',
          endTime: '08:00',
        ),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            doNotDisturbEnabled: true,
            doNotDisturbStart: '23:00',
            doNotDisturbEnd: '08:00',
          )),
        ],
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'disables do not disturb mode',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          doNotDisturbEnabled: true,
          doNotDisturbStart: '22:00',
          doNotDisturbEnd: '07:00',
        )),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) => cubit.setDoNotDisturb(enabled: false),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            doNotDisturbEnabled: false,
            doNotDisturbStart: '22:00',
            doNotDisturbEnd: '07:00',
          )),
        ],
      );
    });

    group('Error handling and rollback', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'rolls back sound setting on API failure and clears errorMessage',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          soundEnabled: true,
        )),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenThrow(Exception('API error'));
          return createCubit();
        },
        act: (cubit) => cubit.setSoundEnabled(false),
        expect: () => [
          const NotificationSettingsState.loaded(NotificationSettings(
            soundEnabled: false,
          )),
          isA<NotificationSettingsState>()
              .having((s) => s.status, 'status', NotificationSettingsStatus.error)
              .having((s) => s.settings.soundEnabled, 'soundEnabled', true)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
          isA<NotificationSettingsState>()
              .having((s) => s.status, 'status', NotificationSettingsStatus.loaded)
              .having((s) => s.settings.soundEnabled, 'soundEnabled', true)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'preserves other settings during rollback',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings(
          messageNotification: false,
          soundEnabled: true,
          vibrationEnabled: false,
        )),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenThrow(Exception('API error'));
          return createCubit();
        },
        act: (cubit) => cubit.setSoundEnabled(false),
        verify: (cubit) {
          expect(cubit.state.settings.messageNotification, isFalse);
          expect(cubit.state.settings.soundEnabled, isTrue);
          expect(cubit.state.settings.vibrationEnabled, isFalse);
        },
      );
    });

    group('Complex scenarios', () {
      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'handles multiple rapid updates',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) async {
          await cubit.setMessageNotification(false);
          await cubit.setSoundEnabled(false);
          await cubit.setVibrationEnabled(false);
        },
        verify: (cubit) {
          expect(cubit.state.settings.messageNotification, isFalse);
          expect(cubit.state.settings.soundEnabled, isFalse);
          expect(cubit.state.settings.vibrationEnabled, isFalse);
        },
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'maintains state consistency across multiple operations',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {});
          return createCubit();
        },
        act: (cubit) async {
          await cubit.setMessageNotification(false);
          await cubit.setNotificationPreviewMode(NotificationPreviewMode.nameOnly);
          await cubit.setDoNotDisturb(
            enabled: true,
            startTime: '22:00',
            endTime: '07:00',
          );
        },
        verify: (cubit) {
          expect(cubit.state.settings.messageNotification, isFalse);
          expect(
            cubit.state.settings.notificationPreviewMode,
            NotificationPreviewMode.nameOnly,
          );
          expect(cubit.state.settings.doNotDisturbEnabled, isTrue);
          expect(cubit.state.settings.doNotDisturbStart, '22:00');
          expect(cubit.state.settings.doNotDisturbEnd, '07:00');
        },
      );

      blocTest<NotificationSettingsCubit, NotificationSettingsState>(
        'handles partial failures in sequence',
        seed: () => const NotificationSettingsState.loaded(NotificationSettings()),
        build: () {
          var callCount = 0;
          when(() => mockSettingsRepository.updateNotificationSettings(any()))
              .thenAnswer((_) async {
            callCount++;
            if (callCount == 2) {
              throw Exception('Second call failed');
            }
          });
          return createCubit();
        },
        act: (cubit) async {
          await cubit.setMessageNotification(false);
          await cubit.setSoundEnabled(false);
          await cubit.setVibrationEnabled(false);
        },
        verify: (cubit) {
          expect(cubit.state.settings.messageNotification, isFalse);
          expect(cubit.state.settings.soundEnabled, isTrue);
          expect(cubit.state.settings.vibrationEnabled, isFalse);
        },
      );
    });
  });
}
