import 'package:equatable/equatable.dart';
import '../../../domain/entities/profile_history.dart';
import '../../../domain/entities/user.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  success,
  failure,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final List<ProfileHistory> histories;
  final ProfileHistoryType? filterType;
  final String? errorMessage;
  final String? successMessage;
  final User? viewingUser;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.histories = const [],
    this.filterType,
    this.errorMessage,
    this.successMessage,
    this.viewingUser,
  });

  const ProfileState.initial() : this();

  ProfileState copyWith({
    ProfileStatus? status,
    List<ProfileHistory>? histories,
    ProfileHistoryType? filterType,
    String? errorMessage,
    String? successMessage,
    User? viewingUser,
    bool clearFilterType = false,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      histories: histories ?? this.histories,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      viewingUser: viewingUser ?? this.viewingUser,
    );
  }

  /// 현재 사용 중인 프로필 이력 (특정 유형)
  ProfileHistory? getCurrentHistory(ProfileHistoryType type) {
    try {
      return histories.firstWhere(
        (h) => h.type == type && h.isCurrent,
      );
    } catch (_) {
      return null;
    }
  }

  /// 특정 유형의 이력 목록
  List<ProfileHistory> getHistoriesByType(ProfileHistoryType type) {
    return histories.where((h) => h.type == type).toList();
  }

  @override
  List<Object?> get props => [
        status,
        histories,
        filterType,
        errorMessage,
        successMessage,
        viewingUser,
      ];
}
