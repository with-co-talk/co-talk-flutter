import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/friend.dart';
import '../../../l10n/app_localizations.dart';
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
          title: Text(
            AppLocalizations.of(context)!.friendsReceivedTitle,
            style: const TextStyle(
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
                title: AppLocalizations.of(context)!.friendsReceivedLoadError,
                subtitle: '네트워크 상태를 확인하고 다시 시도해 주세요.',
                action: SizedBox(
                  width: 160,
                  child: GradientButton(
                    height: 48,
                    label: AppLocalizations.of(context)!.commonRetry,
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      context.read<FriendBloc>().add(const ReceivedFriendRequestsLoadRequested());
                    },
                  ),
                ),
              );
            }

            if (state.receivedRequests.isEmpty) {
              return EmptyStateView(
                icon: Icons.inbox_outlined,
                title: AppLocalizations.of(context)!.friendsReceivedEmptyTitle,
                subtitle: AppLocalizations.of(context)!.friendsReceivedEmptyDesc,
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
                  return _ReceivedRequestTile(
                    request: request,
                    isProcessing:
                        state.processingRequestIds.contains(request.id),
                  );
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
  final bool isProcessing;

  const _ReceivedRequestTile({
    required this.request,
    this.isProcessing = false,
  });

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
                    ? CachedNetworkImageProvider(
                        request.requester.avatarUrl!,
                        maxWidth: 200,
                      )
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
                  // 처리 중에는 비활성화하여 더블탭 중복 호출(거짓 에러)을 막는다.
                  onPressed: isProcessing
                      ? null
                      : () {
                          // 거절은 가벼운 '선택' 피드백(selection), 수락은 더 분명한
                          // light() 로 의도적으로 차별화한다. 긍정 액션(수락)에 더
                          // 또렷한 촉감을 주어 두 버튼의 결과를 손끝으로 구분한다.
                          AppHaptics.selection();
                          context
                              .read<FriendBloc>()
                              .add(FriendRequestRejected(request.id));
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textSecondaryColor,
                    side: BorderSide(color: context.dividerColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.friendsReject,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  height: 46,
                  label: AppLocalizations.of(context)!.friendsAccept,
                  isLoading: isProcessing,
                  onPressed: isProcessing
                      ? null
                      : () {
                          AppHaptics.light();
                          context
                              .read<FriendBloc>()
                              .add(FriendRequestAccepted(request.id));
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
