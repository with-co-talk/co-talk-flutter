import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/chat_settings.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/chat_settings_cubit.dart';
import 'package:co_talk_flutter/presentation/blocs/settings/chat_settings_state.dart';
import '../mocks/mock_repositories.dart';

void main() {
  late ChatSettingsCubit cubit;
  late MockSettingsRepository mockSettingsRepository;

  setUpAll(() {
    registerFallbackValue(const ChatSettings());
  });

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    when(() => mockSettingsRepository.saveChatSettings(any()))
        .thenAnswer((_) async {});
    cubit = ChatSettingsCubit(mockSettingsRepository);
  });

  tearDown(() => cubit.close());

  group('ChatSettingsCubit', () {
    group('loadSettings', () {
      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'emits [loading, loaded] when settings load successfully',
        build: () {
          when(() => mockSettingsRepository.getChatSettings())
              .thenAnswer((_) async => const ChatSettings(fontSize: 1.2));
          return cubit;
        },
        act: (cubit) => cubit.loadSettings(),
        expect: () => [
          const ChatSettingsState.loading(),
          const ChatSettingsState.loaded(ChatSettings(fontSize: 1.2)),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'emits [loading, loaded with defaults] when settings load fails',
        build: () {
          when(() => mockSettingsRepository.getChatSettings())
              .thenThrow(Exception('load failed'));
          return cubit;
        },
        act: (cubit) => cubit.loadSettings(),
        expect: () => [
          const ChatSettingsState.loading(),
          const ChatSettingsState.loaded(ChatSettings()),
        ],
      );
    });

    group('setFontSize', () {
      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'rounds floating-point precision issues (1.0000000000000002 -> 1.0)',
        seed: () => const ChatSettingsState.loaded(ChatSettings(fontSize: 1.2)),
        build: () => cubit,
        act: (cubit) => cubit.setFontSize(1.0000000000000002),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(fontSize: 1.0),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'correctly rounds 0.9999999999999998 to 1.0',
        seed: () => const ChatSettingsState.loaded(ChatSettings(fontSize: 1.2)),
        build: () => cubit,
        act: (cubit) => cubit.setFontSize(0.9999999999999998),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(fontSize: 1.0),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'handles normal values correctly (1.2)',
        seed: () => const ChatSettingsState.loaded(ChatSettings()),
        build: () => cubit,
        act: (cubit) => cubit.setFontSize(1.2),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(fontSize: 1.2),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'clamps values below 0.8 to 0.8',
        seed: () => const ChatSettingsState.loaded(ChatSettings()),
        build: () => cubit,
        act: (cubit) => cubit.setFontSize(0.5),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(fontSize: 0.8),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'clamps values above 1.4 to 1.4',
        seed: () => const ChatSettingsState.loaded(ChatSettings()),
        build: () => cubit,
        act: (cubit) => cubit.setFontSize(2.0),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(fontSize: 1.4),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'rounds Slider division artifact 1.1000000000000001 to 1.1',
        seed: () => const ChatSettingsState.loaded(ChatSettings()),
        build: () => cubit,
        act: (cubit) => cubit.setFontSize(1.1000000000000001),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(fontSize: 1.1),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'saves settings to repository after emit',
        seed: () => const ChatSettingsState.loaded(ChatSettings()),
        build: () => cubit,
        act: (cubit) => cubit.setFontSize(1.2),
        verify: (_) {
          verify(() => mockSettingsRepository
              .saveChatSettings(const ChatSettings(fontSize: 1.2))).called(1);
        },
      );
    });

    group('setShowTypingIndicator', () {
      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'enables typing indicator',
        seed: () => const ChatSettingsState.loaded(ChatSettings()),
        build: () => cubit,
        act: (cubit) => cubit.setShowTypingIndicator(true),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(showTypingIndicator: true),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'disables typing indicator',
        seed: () => const ChatSettingsState.loaded(
            ChatSettings(showTypingIndicator: true)),
        build: () => cubit,
        act: (cubit) => cubit.setShowTypingIndicator(false),
        expect: () => [
          const ChatSettingsState(
            status: ChatSettingsStatus.loaded,
            settings: ChatSettings(showTypingIndicator: false),
          ),
        ],
      );

      blocTest<ChatSettingsCubit, ChatSettingsState>(
        'default showTypingIndicator is false',
        seed: () => const ChatSettingsState.loaded(ChatSettings()),
        build: () => cubit,
        act: (cubit) {},
        verify: (_) {
          expect(cubit.state.settings.showTypingIndicator, isFalse);
        },
      );
    });
  });
}
