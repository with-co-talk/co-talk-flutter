import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/friend.dart';
import '../../blocs/friend/friend_bloc.dart';
import '../../blocs/friend/friend_event.dart';
import '../../blocs/friend/friend_state.dart';

class SentRequestsPage extends StatelessWidget {
  const SentRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FriendBloc>()..add(const SentFriendRequestsLoadRequested()),
      child: const _SentRequestsView(),
    );
  }
}

class _SentRequestsView extends StatelessWidget {
  const _SentRequestsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendBloc, FriendState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage && current.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorMessageMapper.toUserFriendlyMessage(state.errorMessage!)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.friendSettings);
              }
            },
          ),
          title: const Text(
            '보낸 친구 요청',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocBuilder<FriendBloc, FriendState>(
          builder: (context, state) {
            if (state.status == FriendStatus.loading && state.sentRequests.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null && state.sentRequests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: context.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '보낸 친구 요청을 불러오는데 실패했습니다',
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FriendBloc>().add(const SentFriendRequestsLoadRequested());
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            if (state.sentRequests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send_outlined,
                      size: 64,
                      color: context.textSecondaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '보낸 친구 요청이 없습니다',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '친구를 검색하여 요청을 보내보세요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.textSecondaryColor.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FriendBloc>().add(const SentFriendRequestsLoadRequested());
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.sentRequests.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: context.dividerColor,
                ),
                itemBuilder: (context, index) {
                  final request = state.sentRequests[index];
                  return _SentRequestTile(request: request);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SentRequestTile extends StatelessWidget {
  final FriendRequest request;

  const _SentRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: request.receiver.avatarUrl != null
                ? NetworkImage(request.receiver.avatarUrl!)
                : null,
            child: request.receiver.avatarUrl == null
                ? Text(
                    request.receiver.nickname.isNotEmpty
                        ? request.receiver.nickname[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.receiver.nickname,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.receiver.email,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.textSecondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '대기 중',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
