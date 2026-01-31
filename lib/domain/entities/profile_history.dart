import 'package:equatable/equatable.dart';

/// 프로필 이력 유형
enum ProfileHistoryType { avatar, background, statusMessage }

/// 프로필 이력 엔티티.
/// 사용자의 프로필 사진, 배경화면, 상태메시지 변경 이력을 나타낸다.
class ProfileHistory extends Equatable {
  final int id;
  final int userId;
  final ProfileHistoryType type;
  final String? url;
  final String? content;
  final bool isPrivate;
  final bool isCurrent;
  final DateTime createdAt;

  const ProfileHistory({
    required this.id,
    required this.userId,
    required this.type,
    this.url,
    this.content,
    this.isPrivate = false,
    this.isCurrent = false,
    required this.createdAt,
  });

  ProfileHistory copyWith({
    int? id,
    int? userId,
    ProfileHistoryType? type,
    String? url,
    String? content,
    bool? isPrivate,
    bool? isCurrent,
    DateTime? createdAt,
  }) {
    return ProfileHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      url: url ?? this.url,
      content: content ?? this.content,
      isPrivate: isPrivate ?? this.isPrivate,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        url,
        content,
        isPrivate,
        isCurrent,
        createdAt,
      ];
}
