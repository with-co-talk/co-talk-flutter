import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_mapper.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/user.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/friend/friend_bloc.dart';
import '../../blocs/friend/friend_event.dart';
import '../../blocs/friend/friend_state.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FriendBloc>()..add(const BlockedUsersLoadRequested()),
      child: const _BlockedUsersView(),
    );
  }
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

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
            AppLocalizations.of(context)!.friendsBlockedTitle,
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
            if (state.isBlockedUsersLoading && state.blockedUsers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null && state.blockedUsers.isEmpty) {
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
                      AppLocalizations.of(context)!.friendsBlockedLoadError,
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FriendBloc>().add(const BlockedUsersLoadRequested());
                      },
                      child: Text(AppLocalizations.of(context)!.commonRetry),
                    ),
                  ],
                ),
              );
            }

            if (state.blockedUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block_outlined,
                      size: 64,
                      color: context.textSecondaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.friendsBlockedEmptyTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.friendsBlockedEmptyDesc,
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
                context.read<FriendBloc>().add(const BlockedUsersLoadRequested());
              },
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.blockedUsers.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: context.dividerColor,
                ),
                itemBuilder: (context, index) {
                  final user = state.blockedUsers[index];
                  return _BlockedUserTile(user: user);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final User user;

  const _BlockedUserTile({required this.user});

  Future<bool> _showUnblockConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.friendsUnblock),
        content: Text(
          AppLocalizations.of(context)!.friendsUnblockConfirm(user.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(AppLocalizations.of(context)!.friendsUnblock),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: user.avatarUrl != null
                ? CachedNetworkImageProvider(
                    user.avatarUrl!,
                    maxWidth: 200,
                  )
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.nickname.isNotEmpty
                        ? user.nickname[0].toUpperCase()
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
                  user.nickname,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final confirmed = await _showUnblockConfirmDialog(context);
              if (!confirmed) return;

              if (context.mounted) {
                context.read<FriendBloc>().add(UnblockUserRequested(user.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!
                          .friendsUnblockSuccess(user.nickname),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: Text(AppLocalizations.of(context)!.friendsUnblock),
          ),
        ],
      ),
    );
  }
}
