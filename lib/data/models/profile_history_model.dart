import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/profile_history.dart';

part 'profile_history_model.g.dart';

@JsonSerializable()
class ProfileHistoryModel {
  final int id;
  final int userId;
  final String type;
  final String? url;
  final String? content;
  final bool isPrivate;
  final bool isCurrent;
  final DateTime createdAt;

  const ProfileHistoryModel({
    required this.id,
    required this.userId,
    required this.type,
    this.url,
    this.content,
    this.isPrivate = false,
    this.isCurrent = false,
    required this.createdAt,
  });

  factory ProfileHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileHistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileHistoryModelToJson(this);

  ProfileHistory toEntity() {
    return ProfileHistory(
      id: id,
      userId: userId,
      type: _parseType(type),
      url: url,
      content: content,
      isPrivate: isPrivate,
      isCurrent: isCurrent,
      createdAt: createdAt,
    );
  }

  static ProfileHistoryType _parseType(String value) {
    switch (value.toUpperCase()) {
      case 'AVATAR':
        return ProfileHistoryType.avatar;
      case 'BACKGROUND':
        return ProfileHistoryType.background;
      case 'STATUS_MESSAGE':
        return ProfileHistoryType.statusMessage;
      default:
        return ProfileHistoryType.avatar;
    }
  }

  static String typeToString(ProfileHistoryType type) {
    switch (type) {
      case ProfileHistoryType.avatar:
        return 'AVATAR';
      case ProfileHistoryType.background:
        return 'BACKGROUND';
      case ProfileHistoryType.statusMessage:
        return 'STATUS_MESSAGE';
    }
  }
}
