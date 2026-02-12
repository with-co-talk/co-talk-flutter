import 'package:equatable/equatable.dart';

enum GroupImageStatus { initial, uploading, success, error }

class GroupImageState extends Equatable {
  final GroupImageStatus status;
  final String? imageUrl;
  final String? errorMessage;

  const GroupImageState({
    this.status = GroupImageStatus.initial,
    this.imageUrl,
    this.errorMessage,
  });

  GroupImageState copyWith({
    GroupImageStatus? status,
    String? imageUrl,
    String? errorMessage,
  }) {
    return GroupImageState(
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, imageUrl, errorMessage];
}
