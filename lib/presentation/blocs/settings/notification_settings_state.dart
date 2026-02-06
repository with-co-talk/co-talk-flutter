import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification_settings.dart';

enum NotificationSettingsStatus { initial, loading, loaded, error }

/// 알림 설정 상태
class NotificationSettingsState extends Equatable {
  final NotificationSettingsStatus status;
  final NotificationSettings settings;
  final String? errorMessage;

  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.initial,
    this.settings = const NotificationSettings(),
    this.errorMessage,
  });

  const NotificationSettingsState.initial() : this();

  const NotificationSettingsState.loading()
      : this(status: NotificationSettingsStatus.loading);

  const NotificationSettingsState.loaded(NotificationSettings settings)
      : this(status: NotificationSettingsStatus.loaded, settings: settings);

  const NotificationSettingsState.error(String message)
      : this(status: NotificationSettingsStatus.error, errorMessage: message);

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationSettings? settings,
    String? errorMessage,
  }) {
    return NotificationSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
