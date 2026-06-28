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
            AppLocalizations.of(context)!.friendsSentTitle,
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
            if (state.status == FriendStatus.loading && state.sentRequests.isEmpty) {
              return const ListSkeleton();
            }

            if (state.errorMessage != null && state.sentRequests.isEmpty) {
              return EmptyStateView(
                icon: Icons.cloud_off_rounded,
                title: AppLocalizations.of(context)!.friendsSentLoadError,
                subtitle: '네트워크 상태를 확인하고 다시 시도해 주세요.',
                action: SizedBox(
                  width: 160,
                  child: GradientButton(
                    height: 48,
                    label: AppLocalizations.of(context)!.commonRetry,
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      context.read<FriendBloc>().add(const SentFriendRequestsLoadRequested());
                    },
                  ),
                ),
              );
            }

            if (state.sentRequests.isEmpty) {
              return EmptyStateView(
                icon: Icons.send_outlined,
                title: AppLocalizations.of(context)!.friendsSentEmptyTitle,
                subtitle: AppLocalizations.of(context)!.friendsSentEmptyDesc,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FriendBloc>().add(const SentFriendRequestsLoadRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: state.sentRequests.length,
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: request.receiver.avatarUrl != null
                ? CachedNetworkImageProvider(
                    request.receiver.avatarUrl!,
                    maxWidth: 200,
                  )
                : null,
            child: request.receiver.avatarUrl == null
                ? Text(
                    request.receiver.nickname.isNotEmpty
                        ? request.receiver.nickname[0].toUpperCase()
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
                  request.receiver.nickname,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  request.receiver.email,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppLocalizations.of(context)!.friendsSentPending,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
