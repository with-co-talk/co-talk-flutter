import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../domain/entities/chat_room.dart';
import '../../../../blocs/chat/chat_list_bloc.dart';
import '../../../../blocs/chat/chat_list_state.dart';

/// Dialog for selecting a chat room to forward a message to.
class ForwardRoomPickerDialog extends StatefulWidget {
  final ValueChanged<int> onRoomSelected;

  const ForwardRoomPickerDialog({super.key, required this.onRoomSelected});

  @override
  State<ForwardRoomPickerDialog> createState() => _ForwardRoomPickerDialogState();
}

class _ForwardRoomPickerDialogState extends State<ForwardRoomPickerDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.chatSelectRoom),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.chatSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<ChatListBloc, ChatListState>(
                builder: (context, state) {
                  final rooms = state.chatRooms.where((room) {
                    if (_searchQuery.isEmpty) return true;
                    final name = room.displayName.toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (rooms.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)!.chatRoomListEmpty));
                  }

                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(
                            room.type == ChatRoomType.group
                                ? Icons.group
                                : Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          room.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onRoomSelected(room.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.commonCancel),
        ),
      ],
    );
  }
}
