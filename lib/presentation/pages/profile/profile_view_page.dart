import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/profile_history.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
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
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, profileState) {
        // 프로필 변경 성공 시 AuthBloc의 user도 업데이트
        if (profileState.status == ProfileStatus.success && isMyProfile) {
          final viewingUser = profileState.viewingUser;
          if (viewingUser != null) {
            context.read<AuthBloc>().add(AuthUserLocalUpdated(
              avatarUrl: viewingUser.avatarUrl,
              backgroundUrl: viewingUser.backgroundUrl,
              statusMessage: viewingUser.statusMessage,
            ));
          }
        }
      },
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

        if (kDebugMode) {
          debugPrint('[ProfileViewPage] avatarHistory?.url=${avatarHistory?.url}, user.avatarUrl=${user.avatarUrl}');
          debugPrint('[ProfileViewPage] histories count=${profileState.histories.length}, avatarHistories=${profileState.histories.where((h) => h.type == ProfileHistoryType.avatar).map((h) => "id=${h.id}, isCurrent=${h.isCurrent}, url=${h.url}").toList()}');
        }

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
                onTap: () => _openHistoryPage(
                  context,
                  ProfileHistoryType.background,
                  user,
                ),
                onLongPress: isMyProfile
                    ? () => _showBackgroundOptions(context, user)
                    : null,
                child: _BackgroundImage(
                  url: backgroundHistory?.url ?? user.backgroundUrl,
                ),
              ),

              // 그라데이션 오버레이
              IgnorePointer(
                child: Container(
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
              ),

              // 프로필 정보
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 프로필 사진
                    GestureDetector(
                      onTap: () => _openHistoryPage(
                        context,
                        ProfileHistoryType.avatar,
                        user,
                      ),
                      onLongPress: isMyProfile
                          ? () => _showAvatarOptions(context, user)
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
                          ? () => _showStatusMessageDialog(context, user)
                          : null,
                      onLongPress: isMyProfile
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

  void _showStatusMessageDialog(BuildContext context, User user) {
    final controller = TextEditingController(text: user.statusMessage ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('상태메시지'),
        content: TextField(
          controller: controller,
          maxLength: 60,
          maxLines: 2,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '상태메시지를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final newMessage = controller.text.trim();
              context.read<ProfileBloc>().add(
                    ProfileHistoryCreateRequested(
                      userId: userId,
                      type: ProfileHistoryType.statusMessage,
                      content: newMessage.isEmpty ? null : newMessage,
                      setCurrent: true,
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showBackgroundOptions(BuildContext context, User user) {
    final profileBloc = context.read<ProfileBloc>();
    final backgroundHistory = profileBloc.state.getCurrentHistory(ProfileHistoryType.background);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '배경화면',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // 전체화면 보기
              if (backgroundHistory?.url != null || user.backgroundUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen, color: Colors.blue),
                  ),
                  title: const Text('전체 화면 보기'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showFullScreenImage(
                      context,
                      backgroundHistory?.url ?? user.backgroundUrl!,
                    );
                  },
                ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('배경화면 변경'),
                subtitle: const Text('앨범에서 새 배경 선택'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickBackgroundImage(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: Colors.grey),
                ),
                title: const Text('배경화면 이력'),
                subtitle: const Text('이전 배경화면 보기'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openHistoryPage(context, ProfileHistoryType.background, user);
                },
              ),
              // 나만 보기
              if (backgroundHistory != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      backgroundHistory.isPrivate ? Icons.visibility_off : Icons.visibility,
                      color: Colors.orange,
                    ),
                  ),
                  title: Text(backgroundHistory.isPrivate ? '전체 공개로 변경' : '나만 보기'),
                  subtitle: Text(backgroundHistory.isPrivate ? '다른 사람에게 공개됩니다' : '나만 볼 수 있습니다'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    profileBloc.add(ProfileHistoryPrivacyToggled(
                      userId: userId,
                      historyId: backgroundHistory.id,
                      isPrivate: !backgroundHistory.isPrivate,
                    ));
                  },
                ),
              // 삭제
              if (backgroundHistory != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showDeleteConfirmDialog(
                      context,
                      '배경화면',
                      () => profileBloc.add(ProfileHistoryDeleteRequested(
                        userId: userId,
                        historyId: backgroundHistory.id,
                      )),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, User user) {
    final profileBloc = context.read<ProfileBloc>();
    final avatarHistory = profileBloc.state.getCurrentHistory(ProfileHistoryType.avatar);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '프로필 사진',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // 전체화면 보기
              if (avatarHistory?.url != null || user.avatarUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen, color: Colors.blue),
                  ),
                  title: const Text('전체 화면 보기'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showFullScreenImage(
                      context,
                      avatarHistory?.url ?? user.avatarUrl!,
                    );
                  },
                ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('프로필 사진 변경'),
                subtitle: const Text('앨범에서 새 사진 선택'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatarImage(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: Colors.grey),
                ),
                title: const Text('프로필 사진 이력'),
                subtitle: const Text('이전 프로필 사진 보기'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openHistoryPage(context, ProfileHistoryType.avatar, user);
                },
              ),
              // 나만 보기
              if (avatarHistory != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      avatarHistory.isPrivate ? Icons.visibility_off : Icons.visibility,
                      color: Colors.orange,
                    ),
                  ),
                  title: Text(avatarHistory.isPrivate ? '전체 공개로 변경' : '나만 보기'),
                  subtitle: Text(avatarHistory.isPrivate ? '다른 사람에게 공개됩니다' : '나만 볼 수 있습니다'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    profileBloc.add(ProfileHistoryPrivacyToggled(
                      userId: userId,
                      historyId: avatarHistory.id,
                      isPrivate: !avatarHistory.isPrivate,
                    ));
                  },
                ),
              // 삭제
              if (avatarHistory != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('삭제', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showDeleteConfirmDialog(
                      context,
                      '프로필 사진',
                      () => profileBloc.add(ProfileHistoryDeleteRequested(
                        userId: userId,
                        historyId: avatarHistory.id,
                      )),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _DismissibleProfileImageViewer(imageUrl: imageUrl);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$itemName 삭제'),
        content: Text('$itemName을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundImage(BuildContext context) async {
    final imagePicker = ImagePicker();
    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null && context.mounted) {
        context.read<ProfileBloc>().add(
              ProfileHistoryCreateRequested(
                userId: userId,
                type: ProfileHistoryType.background,
                imageFile: File(pickedFile.path),
                setCurrent: true,
              ),
            );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 선택할 수 없습니다')),
        );
      }
    }
  }

  Future<void> _pickAvatarImage(BuildContext context) async {
    final imagePicker = ImagePicker();
    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null && context.mounted) {
        context.read<ProfileBloc>().add(
              ProfileHistoryCreateRequested(
                userId: userId,
                type: ProfileHistoryType.avatar,
                imageFile: File(pickedFile.path),
                setCurrent: true,
              ),
            );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 선택할 수 없습니다')),
        );
      }
    }
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
          onTap: () => _startDirectChat(context, userId),
        ),
      ],
    );
  }

  void _startDirectChat(BuildContext context, int targetUserId) {
    // ChatRepository를 통해 1:1 채팅방 생성/조회 후 이동
    context.push('/chat/direct/$targetUserId');
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
          onTap: () => _startSelfChat(context),
        ),
        const SizedBox(width: 40),
        _ActionButton(
          icon: Icons.edit_outlined,
          label: '프로필 편집',
          onTap: () async {
            await context.push('/profile/edit');
            if (context.mounted) {
              // 편집 후 돌아오면 최신 프로필 데이터 다시 로드
              final profileBloc = context.read<ProfileBloc>();
              profileBloc.add(ProfileUserLoadRequested(userId: user.id));
              profileBloc.add(ProfileHistoryLoadRequested(userId: user.id));
            }
          },
        ),
      ],
    );
  }

  void _startSelfChat(BuildContext context) {
    // AuthBloc에서 현재 로그인한 사용자 ID를 가져옴 (viewingUser와 혼동 방지)
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보를 찾을 수 없습니다')),
      );
      return;
    }
    // 자기 자신과의 채팅방으로 이동 (메모용)
    context.push('/chat/self/$currentUserId');
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

/// 드래그로 닫을 수 있는 프로필 이미지 뷰어 (카카오톡 스타일)
class _DismissibleProfileImageViewer extends StatefulWidget {
  final String imageUrl;

  const _DismissibleProfileImageViewer({required this.imageUrl});

  @override
  State<_DismissibleProfileImageViewer> createState() =>
      _DismissibleProfileImageViewerState();
}

class _DismissibleProfileImageViewerState
    extends State<_DismissibleProfileImageViewer>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  double _dragVelocity = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const double _dismissThreshold = 100;
  static const double _velocityThreshold = 500;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.addListener(() {
      setState(() {
        _dragOffset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragVelocity = details.velocity.pixelsPerSecond.dy;

    final shouldDismiss = _dragOffset.abs() > _dismissThreshold ||
        _dragVelocity.abs() > _velocityThreshold;

    if (shouldDismiss) {
      Navigator.of(context).pop();
    } else {
      _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);
    final scale = (1 - (_dragOffset.abs() / 1000)).clamp(0.8, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white.withValues(alpha: opacity)),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                scale: scale,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 80),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
