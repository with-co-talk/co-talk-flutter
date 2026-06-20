import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../di/injection.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/gradient_button.dart';

/// 1:1 채팅 시작 페이지
/// 채팅방을 생성/조회한 후 해당 채팅방으로 이동한다.
class DirectChatPage extends StatefulWidget {
  final int targetUserId;
  final bool isSelfChat;

  const DirectChatPage({
    super.key,
    required this.targetUserId,
    this.isSelfChat = false,
  });

  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  bool _isLoading = true;
  String? _errorMessage;

  String _selfChatTitle(BuildContext context) {
    final nickname = (context.read<AuthBloc>().state.user?.nickname ?? '').trim();
    return nickname.isNotEmpty ? nickname : '나';
  }

  @override
  void initState() {
    super.initState();
    _createOrGetChatRoom();
  }

  Future<void> _createOrGetChatRoom() async {
    try {
      final chatRepository = getIt<ChatRepository>();
      final chatRoom = await chatRepository.createDirectChatRoom(widget.targetUserId);

      if (mounted) {
        // 채팅방으로 이동 (replace로 현재 페이지 대체)
        context.go('/chat/room/${chatRoom.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '채팅방을 불러올 수 없습니다: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isSelfChat ? _selfChatTitle(context) : '1:1 채팅',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 브랜드 톤의 소프트 글로우 스피너
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '채팅방을 준비 중...',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: '채팅방을 열 수 없어요',
                subtitle: _errorMessage ?? '알 수 없는 오류가 발생했습니다',
                action: SizedBox(
                  width: 200,
                  child: GradientButton(
                    label: '다시 시도',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _createOrGetChatRoom();
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
