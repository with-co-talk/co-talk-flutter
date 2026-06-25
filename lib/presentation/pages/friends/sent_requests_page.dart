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
          title: Text(
            AppLocalizations.of(context)!.friendsSentTitle,
            style: const TextStyle(
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
              return const ListSkeleton();
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
                      AppLocalizations.of(context)!.friendsSentLoadError,
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FriendBloc>().add(const SentFriendRequestsLoadRequested());
                      },
                      child: Text(AppLocalizations.of(context)!.commonRetry),
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
                      AppLocalizations.of(context)!.friendsSentEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.friendsSentEmptyDesc,
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
              AppLocalizations.of(context)!.friendsSentPending,
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
