import 'package:equatable/equatable.dart';

enum AppLockStatus { unlocked, locked, authenticating }

class AppLockState extends Equatable {
  final AppLockStatus status;

  const AppLockState({this.status = AppLockStatus.unlocked});

  const AppLockState.unlocked() : status = AppLockStatus.unlocked;
  const AppLockState.locked() : status = AppLockStatus.locked;
  const AppLockState.authenticating() : status = AppLockStatus.authenticating;

  @override
  List<Object?> get props => [status];
}
