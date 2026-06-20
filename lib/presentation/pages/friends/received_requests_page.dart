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
import '../../widgets/empty_state_view.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skeletons/list_skeleton.dart';
import '../../../core/utils/app_haptics.dart';

class ReceivedRequestsPage extends StatelessWidget {
  const ReceivedRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FriendBloc>()..add(const ReceivedFriendRequestsLoadRequested()),
      child: const _ReceivedRequestsView(),
    );
  }
}

class _ReceivedRequestsView extends StatelessWidget {
  const _ReceivedRequestsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<FriendBloc, FriendState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage && current.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(ErrorMessageMapper.toUserFriendlyMessage(state.errorMessage!)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
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
            '받은 친구 요청',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 19,
              letterSpacing: -0.4,
            ),
          ),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocBuilder<FriendBloc, FriendState>(
          builder: (context, state) {
            if (state.status == FriendStatus.loading && state.receivedRequests.isEmpty) {
              return const ListSkeleton();
            }

            if (state.errorMessage != null && state.receivedRequests.isEmpty) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: '요청을 불러오지 못했어요',
                subtitle: '네트워크 상태를 확인하고 다시 시도해 주세요.',
                action: SizedBox(
                  width: 160,
                  child: GradientButton(
                    height: 48,
                    label: '다시 시도',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      context.read<FriendBloc>().add(const ReceivedFriendRequestsLoadRequested());
                    },
                  ),
                ),
              );
            }

            if (state.receivedRequests.isEmpty) {
              return const EmptyStateView(
                icon: Icons.inbox_outlined,
                title: '받은 친구 요청이 없어요',
                subtitle: '다른 사용자가 요청을 보내면 여기에 표시돼요.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FriendBloc>().add(const ReceivedFriendRequestsLoadRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: state.receivedRequests.length,
                itemBuilder: (context, index) {
                  final request = state.receivedRequests[index];
                  return _ReceivedRequestTile(request: request);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReceivedRequestTile extends StatelessWidget {
  final FriendRequest request;

  const _ReceivedRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: request.requester.avatarUrl != null
                    ? NetworkImage(request.requester.avatarUrl!)
                    : null,
                child: request.requester.avatarUrl == null
                    ? Text(
                        request.requester.nickname.isNotEmpty
                            ? request.requester.nickname[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requester.nickname,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.requester.email,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.selection();
                    context.read<FriendBloc>().add(FriendRequestRejected(request.id));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textSecondaryColor,
                    side: BorderSide(color: context.dividerColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '거절',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  height: 46,
                  label: '수락',
                  onPressed: () {
                    AppHaptics.light();
                    context.read<FriendBloc>().add(FriendRequestAccepted(request.id));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
