import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../di/injection.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../blocs/auth/auth_bloc.dart';

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
    final nickname = context.read<AuthBloc>().state.user?.nickname?.trim();
    return (nickname != null && nickname.isNotEmpty) ? nickname : '나';
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
      appBar: AppBar(
        title: Text(
          widget.isSelfChat ? _selfChatTitle(context) : '1:1 채팅',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    widget.isSelfChat ? '채팅방을 준비 중...' : '채팅방을 준비 중...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? '알 수 없는 오류가 발생했습니다',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _createOrGetChatRoom();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
      ),
    );
  }
}
