import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final String? status;
  final String? role;
  final String? onlineStatus;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    this.status,
    this.role,
    this.onlineStatus,
    this.lastActiveAt,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() {
    return User(
      id: id,
      email: email,
      nickname: nickname,
      avatarUrl: avatarUrl,
      status: _parseUserStatus(status),
      role: _parseUserRole(role),
      onlineStatus: _parseOnlineStatus(onlineStatus),
      lastActiveAt: lastActiveAt,
      createdAt: createdAt,
    );
  }

  static UserStatus _parseUserStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return UserStatus.active;
      case 'INACTIVE':
        return UserStatus.inactive;
      case 'SUSPENDED':
        return UserStatus.suspended;
      default:
        return UserStatus.active;
    }
  }

  static UserRole _parseUserRole(String? value) {
    switch (value?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  static OnlineStatus _parseOnlineStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'ONLINE':
        return OnlineStatus.online;
      case 'AWAY':
        return OnlineStatus.away;
      case 'DO_NOT_DISTURB':
        return OnlineStatus.doNotDisturb;
      case 'OFFLINE':
      default:
        return OnlineStatus.offline;
    }
  }
}
