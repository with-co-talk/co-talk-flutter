import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/profile_history.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import 'widgets/history_item_options_sheet.dart';

/// 프로필 이력 스와이프 뷰어 페이지
/// 좌우로 스와이프하여 이력을 탐색할 수 있다.
class ProfileHistoryPage extends StatefulWidget {
  final int userId;
  final ProfileHistoryType type;
  final bool isMyProfile;
  final int? initialIndex;

  const ProfileHistoryPage({
    super.key,
    required this.userId,
    required this.type,
    this.isMyProfile = false,
    this.initialIndex,
  });

  @override
  State<ProfileHistoryPage> createState() => _ProfileHistoryPageState();
}

class _ProfileHistoryPageState extends State<ProfileHistoryPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);

    // 해당 타입의 이력을 다시 로드 (서버에서 자동 생성 트리거)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileBloc>().add(
            ProfileHistoryLoadRequested(
              userId: widget.userId,
              type: widget.type,
            ),
          );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.success && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        } else if (state.status == ProfileStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // ignore: avoid_print
        print('[ProfileHistoryPage] Build: status=${state.status}, historiesCount=${state.histories.length}');

        // 로딩 중일 때 로딩 인디케이터 표시
        if (state.status == ProfileStatus.loading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final histories = state.getHistoriesByType(widget.type);

        // ignore: avoid_print
        print('[ProfileHistoryPage] Filtered histories for ${widget.type}: ${histories.length}');

        if (histories.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getEmptyIcon(),
                    color: Colors.white54,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 ${_getTypeLabel()} 이력이 없습니다',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.isMyProfile) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 추가 기능
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.add),
                      label: Text('${_getTypeLabel()} 추가'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // 인덱스 범위 체크
        if (_currentIndex >= histories.length) {
          _currentIndex = histories.length - 1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(_currentIndex);
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _getTypeLabel(),
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 이력 페이지 뷰
              PageView.builder(
                controller: _pageController,
                itemCount: histories.length,
                // 데스크톱에서도 마우스 드래그로 스와이프 가능하도록 설정
                scrollBehavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final history = histories[index];
                  final child = _HistoryItemView(
                    history: history,
                    type: widget.type,
                  );

                  // isMyProfile일 때만 GestureDetector 사용
                  if (!widget.isMyProfile) {
                    return child;
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPress: () => _showOptionsSheet(context, history),
                    child: child,
                  );
                },
              ),

              // 페이지 인디케이터와 날짜
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // 현재 이력 정보
                    if (histories.isNotEmpty)
                      _HistoryInfoOverlay(
                        history: histories[_currentIndex],
                      ),
                    const SizedBox(height: 16),

                    // 페이지 인디케이터
                    if (histories.length > 1)
                      _PageIndicator(
                        total: histories.length,
                        current: _currentIndex,
                      ),
                  ],
                ),
              ),

              // 더보기 버튼 (내 프로필일 때만)
              if (widget.isMyProfile && histories.isNotEmpty)
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _showOptionsSheet(context, histories[_currentIndex]),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.more_horiz, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                '더보기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsSheet(BuildContext context, ProfileHistory history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryItemOptionsSheet(
        history: history,
        isMyProfile: widget.isMyProfile,
        onSetCurrent: () {
          context.read<ProfileBloc>().add(
                ProfileHistorySetCurrentRequested(
                  userId: widget.userId,
                  historyId: history.id,
                ),
              );
        },
        onTogglePrivacy: () {
          context.read<ProfileBloc>().add(
                ProfileHistoryPrivacyToggled(
                  userId: widget.userId,
                  historyId: history.id,
                  isPrivate: !history.isPrivate,
                ),
              );
        },
        onDelete: () {
          context.read<ProfileBloc>().add(
                ProfileHistoryDeleteRequested(
                  userId: widget.userId,
                  historyId: history.id,
                ),
              );
        },
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (widget.type) {
      case ProfileHistoryType.avatar:
        return Icons.person_outline;
      case ProfileHistoryType.background:
        return Icons.image_outlined;
      case ProfileHistoryType.statusMessage:
        return Icons.chat_bubble_outline;
    }
  }

  String _getTypeLabel() {
    switch (widget.type) {
      case ProfileHistoryType.avatar:
        return '프로필 사진';
      case ProfileHistoryType.background:
        return '배경화면';
      case ProfileHistoryType.statusMessage:
        return '상태메시지';
    }
  }
}

class _HistoryItemView extends StatelessWidget {
  final ProfileHistory history;
  final ProfileHistoryType type;

  const _HistoryItemView({
    required this.history,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ProfileHistoryType.avatar:
      case ProfileHistoryType.background:
        return _ImageView(url: history.url);
      case ProfileHistoryType.statusMessage:
        return _StatusMessageView(content: history.content);
    }
  }
}

class _ImageView extends StatefulWidget {
  final String? url;

  const _ImageView({this.url});

  @override
  State<_ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<_ImageView> {
  final TransformationController _transformationController =
      TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url == null || widget.url!.isEmpty) {
      return Container(
        color: AppColors.primaryDark,
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white54,
            size: 64,
          ),
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        // 확대 중일 때만 pan 활성화 (기본 상태에서는 PageView 스와이프 허용)
        panEnabled: _isZoomed,
        child: Center(
          child: Image.network(
            widget.url!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessageView extends StatelessWidget {
  final String? content;

  const _StatusMessageView({this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            content ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _HistoryInfoOverlay extends StatelessWidget {
  final ProfileHistory history;

  const _HistoryInfoOverlay({required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 날짜
        Text(
          _formatDate(history.createdAt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),

        // 배지들
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (history.isCurrent)
              _Badge(
                icon: Icons.check_circle,
                label: '현재',
                color: AppColors.success,
              ),
            if (history.isPrivate)
              _Badge(
                icon: Icons.lock,
                label: '나만보기',
                color: AppColors.warning,
              ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int total;
  final int current;

  const _PageIndicator({
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
