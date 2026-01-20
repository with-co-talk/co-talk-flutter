import 'package:equatable/equatable.dart';

enum UserStatus { active, inactive, suspended }

enum OnlineStatus { online, offline, away }

enum UserRole { user, admin }

class User extends Equatable {
  final int id;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final UserStatus status;
  final UserRole role;
  final OnlineStatus onlineStatus;
  final DateTime? lastActiveAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    this.status = UserStatus.active,
    this.role = UserRole.user,
    this.onlineStatus = OnlineStatus.offline,
    this.lastActiveAt,
    required this.createdAt,
  });

  User copyWith({
    int? id,
    String? email,
    String? nickname,
    String? avatarUrl,
    UserStatus? status,
    UserRole? role,
    OnlineStatus? onlineStatus,
    DateTime? lastActiveAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      role: role ?? this.role,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        nickname,
        avatarUrl,
        status,
        role,
        onlineStatus,
        lastActiveAt,
        createdAt,
      ];
}
