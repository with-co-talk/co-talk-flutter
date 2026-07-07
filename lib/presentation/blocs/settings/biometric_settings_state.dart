import 'package:equatable/equatable.dart';

enum BiometricSettingsStatus { initial, loading, loaded, error }

class BiometricSettingsState extends Equatable {
  final bool isSupported;
  final bool isEnabled;
  final BiometricSettingsStatus status;

  const BiometricSettingsState({
    this.isSupported = false,
    this.isEnabled = false,
    this.status = BiometricSettingsStatus.initial,
  });

  BiometricSettingsState copyWith({
    bool? isSupported,
    bool? isEnabled,
    BiometricSettingsStatus? status,
  }) {
    return BiometricSettingsState(
      isSupported: isSupported ?? this.isSupported,
      isEnabled: isEnabled ?? this.isEnabled,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [isSupported, isEnabled, status];
}
