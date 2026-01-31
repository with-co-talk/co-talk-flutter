import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/profile_history.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// 사용자 프로필 정보 로드 요청
class ProfileUserLoadRequested extends ProfileEvent {
  final int userId;

  const ProfileUserLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// 프로필 이력 목록 로드 요청
class ProfileHistoryLoadRequested extends ProfileEvent {
  final int userId;
  final ProfileHistoryType? type;

  const ProfileHistoryLoadRequested({
    required this.userId,
    this.type,
  });

  @override
  List<Object?> get props => [userId, type];
}

/// 프로필 이력 생성 요청 (이미지 업로드 포함)
class ProfileHistoryCreateRequested extends ProfileEvent {
  final int userId;
  final ProfileHistoryType type;
  final File? imageFile;
  final String? content;
  final bool isPrivate;
  final bool setCurrent;

  const ProfileHistoryCreateRequested({
    required this.userId,
    required this.type,
    this.imageFile,
    this.content,
    this.isPrivate = false,
    this.setCurrent = true,
  });

  @override
  List<Object?> get props => [userId, type, imageFile, content, isPrivate, setCurrent];
}

/// 프로필 이력 나만보기 토글 요청
class ProfileHistoryPrivacyToggled extends ProfileEvent {
  final int userId;
  final int historyId;
  final bool isPrivate;

  const ProfileHistoryPrivacyToggled({
    required this.userId,
    required this.historyId,
    required this.isPrivate,
  });

  @override
  List<Object?> get props => [userId, historyId, isPrivate];
}

/// 프로필 이력 삭제 요청
class ProfileHistoryDeleteRequested extends ProfileEvent {
  final int userId;
  final int historyId;

  const ProfileHistoryDeleteRequested({
    required this.userId,
    required this.historyId,
  });

  @override
  List<Object?> get props => [userId, historyId];
}

/// 현재 프로필로 설정 요청
class ProfileHistorySetCurrentRequested extends ProfileEvent {
  final int userId;
  final int historyId;

  const ProfileHistorySetCurrentRequested({
    required this.userId,
    required this.historyId,
  });

  @override
  List<Object?> get props => [userId, historyId];
}
