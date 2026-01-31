import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/profile_history.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import 'profile_history_page.dart';

/// 전체 프로필 뷰 페이지 (카카오톡 스타일)
/// 배경화면, 프로필 사진, 닉네임, 상태메시지를 전체 화면으로 보여준다.
class ProfileViewPage extends StatelessWidget {
  final int userId;
  final bool isMyProfile;

  const ProfileViewPage({
    super.key,
    required this.userId,
    this.isMyProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()
        ..add(ProfileUserLoadRequested(userId: userId))
        ..add(ProfileHistoryLoadRequested(userId: userId)),
      child: _ProfileViewContent(
        userId: userId,
        isMyProfile: isMyProfile,
      ),
    );
  }
}

class _ProfileViewContent extends StatelessWidget {
  final int userId;
  final bool isMyProfile;

  const _ProfileViewContent({
    required this.userId,
    required this.isMyProfile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        final user = profileState.viewingUser;

        if (profileState.status == ProfileStatus.loading || user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profileState.status == ProfileStatus.failure) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    profileState.errorMessage ?? '프로필을 불러올 수 없습니다',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final backgroundHistory = profileState.getCurrentHistory(ProfileHistoryType.background);
        final avatarHistory = profileState.getCurrentHistory(ProfileHistoryType.avatar);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (isMyProfile)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => context.push('/settings'),
                ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 배경화면
              GestureDetector(
                onTap: isMyProfile
                    ? () => _openHistoryPage(
                          context,
                          ProfileHistoryType.background,
                          user,
                        )
                    : null,
                child: _BackgroundImage(
                  url: backgroundHistory?.url ?? user.backgroundUrl,
                ),
              ),

              // 그라데이션 오버레이
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // 프로필 정보
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 프로필 사진
                    GestureDetector(
                      onTap: isMyProfile
                          ? () => _openHistoryPage(
                                context,
                                ProfileHistoryType.avatar,
                                user,
                              )
                          : null,
                      child: _ProfileAvatar(
                        url: avatarHistory?.url ?? user.avatarUrl,
                        nickname: user.nickname,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 닉네임
                    Text(
                      user.nickname,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 상태메시지
                    GestureDetector(
                      onTap: isMyProfile
                          ? () => _openHistoryPage(
                                context,
                                ProfileHistoryType.statusMessage,
                                user,
                              )
                          : null,
                      child: _StatusMessage(
                        message: user.statusMessage,
                        isMyProfile: isMyProfile,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 액션 버튼들
                    if (!isMyProfile)
                      _ProfileActions(userId: userId)
                    else
                      _MyProfileActions(user: user),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openHistoryPage(
    BuildContext context,
    ProfileHistoryType type,
    User user,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: ProfileHistoryPage(
            userId: userId,
            type: type,
            isMyProfile: isMyProfile,
          ),
        ),
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  final String? url;

  const _BackgroundImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.primaryDark,
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? url;
  final String nickname;

  const _ProfileAvatar({
    this.url,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: url != null ? NetworkImage(url!) : null,
        child: url == null
            ? Text(
                nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String? message;
  final bool isMyProfile;

  const _StatusMessage({
    this.message,
    required this.isMyProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      if (isMyProfile) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '상태메시지 추가',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        message!,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  final int userId;

  const _ProfileActions({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: '1:1 채팅',
          onTap: () {
            // TODO: 1:1 채팅 시작
          },
        ),
        const SizedBox(width: 40),
        _ActionButton(
          icon: Icons.videocam_outlined,
          label: '통화',
          onTap: () {
            // TODO: 통화 기능
          },
        ),
      ],
    );
  }
}

class _MyProfileActions extends StatelessWidget {
  final User user;

  const _MyProfileActions({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: '나와의 채팅',
          onTap: () {
            // TODO: 나와의 채팅
          },
        ),
        const SizedBox(width: 40),
        _ActionButton(
          icon: Icons.edit_outlined,
          label: '프로필 편집',
          onTap: () {
            context.push('/profile/edit');
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
