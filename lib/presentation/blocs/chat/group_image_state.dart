import 'package:equatable/equatable.dart';

enum GroupImageStatus { initial, uploading, success, error }

class GroupImageState extends Equatable {
  final GroupImageStatus status;
  final String? imageUrl;

  const GroupImageState({
    this.status = GroupImageStatus.initial,
    this.imageUrl,
  });

  GroupImageState copyWith({
    GroupImageStatus? status,
    String? imageUrl,
  }) {
    return GroupImageState(
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [status, imageUrl];
}
