import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_settings.dart';

enum ChatSettingsStatus { initial, loading, loaded, clearing, error }

/// 채팅 설정 상태
class ChatSettingsState extends Equatable {
  final ChatSettingsStatus status;
  final ChatSettings settings;
  final String? errorMessage;

  const ChatSettingsState({
    this.status = ChatSettingsStatus.initial,
    this.settings = const ChatSettings(),
    this.errorMessage,
  });

  const ChatSettingsState.initial() : this();

  const ChatSettingsState.loading()
      : this(status: ChatSettingsStatus.loading);

  const ChatSettingsState.loaded(ChatSettings settings)
      : this(status: ChatSettingsStatus.loaded, settings: settings);

  const ChatSettingsState.clearing()
      : this(status: ChatSettingsStatus.clearing);

  const ChatSettingsState.error(String message)
      : this(status: ChatSettingsStatus.error, errorMessage: message);

  ChatSettingsState copyWith({
    ChatSettingsStatus? status,
    ChatSettings? settings,
    String? errorMessage,
  }) {
    return ChatSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
