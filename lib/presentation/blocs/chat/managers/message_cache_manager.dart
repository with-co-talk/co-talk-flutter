import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/repositories/chat_repository.dart';

/// Manages message caching and pagination.
///
/// Handles:
/// - Local message caching
/// - Message list state
/// - Pagination cursor management
/// - Cache invalidation
class MessageCacheManager {
  final ChatRepository _chatRepository;

  List<Message> _messages = [];
  int? _nextCursor;
  bool _hasMore = false;
  bool _isOfflineData = false;

  MessageCacheManager(this._chatRepository);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[MessageCacheManager] $message');
    }
  }

  /// Loads cached messages from local storage.
  Future<List<Message>> loadCachedMessages(int roomId) async {
    try {
      final cachedMessages = await _chatRepository.getLocalMessages(
        roomId,
        limit: AppConstants.messagePageSize,
      );

      if (cachedMessages.isNotEmpty) {
        _log('Loaded ${cachedMessages.length} cached messages');
        _messages = cachedMessages;
        _hasMore = cachedMessages.length >= AppConstants.messagePageSize;
        _isOfflineData = true;
        return cachedMessages;
      }
    } catch (e) {
      _log('Failed to load cached messages: $e');
    }

    return [];
  }

  /// Loads messages from the server.
  Future<void> loadMessagesFromServer(int roomId) async {
    final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
      roomId,
      size: AppConstants.messagePageSize,
    );

    _log('Fetched ${messages.length} messages from server');
    _messages = messages;
    _nextCursor = nextCursor;
    _hasMore = hasMore;
    _isOfflineData = false;
  }

  /// Refreshes cache from server for gap recovery (foreground return).
  ///
  /// Fetches the latest messages from server (no cursor = newest),
  /// merges with existing cache (server data wins, pending preserved),
  /// deduplicates by message ID, and returns whether new messages were found.
  Future<bool> refreshFromServer(int roomId) async {
    try {
      final (serverMessages, nextCursor, hasMore) =
          await _chatRepository.getMessages(
        roomId,
        size: AppConstants.messagePageSize,
      );

      _log('refreshFromServer: fetched ${serverMessages.length} messages');

      if (serverMessages.isEmpty) return false;

      // Preserve pending/failed messages (not yet confirmed by server)
      final pendingMsgs =
          _messages.where((m) => m.isPending || m.isFailed).toList();

      // Merge: use server messages as the base, deduplicate
      final serverIds = serverMessages.map((m) => m.id).toSet();
      final existingIds = _messages.map((m) => m.id).toSet();

      // Check if there are genuinely new messages
      final hasNewMessages = serverIds.any((id) => !existingIds.contains(id));

      // Build merged list: pending first, then server messages
      // (pending messages have negative temp IDs so won't collide)
      _messages = [...pendingMsgs, ...serverMessages];

      // Deduplicate by id (keep first occurrence)
      final seenIds = <int>{};
      _messages = _messages.where((m) {
        if (m.isPending || m.isFailed) return true; // always keep pending
        if (seenIds.contains(m.id)) return false;
        seenIds.add(m.id);
        return true;
      }).toList();

      _nextCursor = nextCursor;
      _hasMore = hasMore;
      _isOfflineData = false;

      _log('refreshFromServer: merged to ${_messages.length} messages, hasNew=$hasNewMessages');
      return hasNewMessages;
    } catch (e) {
      _log('refreshFromServer failed: $e (keeping existing cache)');
      return false;
    }
  }

  /// Loads more messages for pagination.
  Future<List<Message>> loadMoreMessages(int roomId) async {
    if (!_hasMore || _nextCursor == null) {
      _log('No more messages to load');
      return _messages;
    }

    try {
      final (messages, nextCursor, hasMore) = await _chatRepository.getMessages(
        roomId,
        size: AppConstants.messagePageSize,
        beforeMessageId: _nextCursor,
      );

      // 중복 메시지 필터링 (이미 존재하는 메시지 ID 제외)
      final existingIds = _messages.map((m) => m.id).toSet();
      final newMessages = messages.where((m) => !existingIds.contains(m.id)).toList();

      if (newMessages.length != messages.length) {
        _log('Filtered ${messages.length - newMessages.length} duplicate messages');
      }

      _messages = [..._messages, ...newMessages];
      _nextCursor = nextCursor;
      _hasMore = hasMore;

      _log('Loaded ${newMessages.length} more messages. Total: ${_messages.length}');
      return _messages;
    } catch (e) {
      _log('Failed to load more messages: $e');
      rethrow;
    }
  }

  /// Adds a new message to the cache.
  void addMessage(Message message) {
    // Check if message already exists
    final existingIndex = _messages.indexWhere((m) => m.id == message.id);

    if (existingIndex != -1) {
      // Update existing message (create new list for Equatable compatibility)
      _messages = [
        for (int i = 0; i < _messages.length; i++)
          if (i == existingIndex) message else _messages[i],
      ];
      _log('Updated existing message: id=${message.id}');
    } else {
      // Add new message at the beginning
      _messages = [message, ..._messages];
      _log('Added new message: id=${message.id}');
    }

    // Fire-and-forget: local DB write runs in background to avoid blocking BLoC event queue.
    // In-memory cache is already updated above, so UI updates instantly.
    _chatRepository.saveMessageLocally(message).catchError((e) {
      _log('Failed to save message locally: $e');
      return null;
    });

    _isOfflineData = false;
  }

  /// Updates an existing message in the cache.
  void updateMessage(int messageId, Message Function(Message) updateFn) {
    _messages = _messages.map((m) {
      if (m.id == messageId) {
        return updateFn(m);
      }
      return m;
    }).toList();

    _log('Updated message: id=$messageId');
  }

  /// Updates all messages matching a predicate.
  void updateMessages(Message Function(Message) updateFn) {
    _messages = _messages.map(updateFn).toList();
  }

  /// Removes a message from the cache.
  void removeMessage(int messageId) {
    _messages = _messages.where((m) => m.id != messageId).toList();
    _log('Removed message: id=$messageId');
  }

  /// Marks a message as deleted.
  void markMessageAsDeleted(int messageId) {
    updateMessage(messageId, (m) => m.copyWith(isDeleted: true));
  }

  /// Adds a reaction to a message.
  void addReaction(int messageId, MessageReaction reaction) {
    updateMessage(messageId, (m) {
      // Check if reaction already exists
      final exists = m.reactions.any(
        (r) => r.userId == reaction.userId && r.emoji == reaction.emoji,
      );
      if (exists) return m;

      return m.copyWith(reactions: [...m.reactions, reaction]);
    });
    _log('Added reaction to message $messageId: ${reaction.emoji}');
  }

  /// Removes a reaction from a message.
  void removeReaction(int messageId, int userId, String emoji) {
    updateMessage(messageId, (m) {
      final updatedReactions = m.reactions
          .where((r) => !(r.userId == userId && r.emoji == emoji))
          .toList();
      return m.copyWith(reactions: updatedReactions);
    });
    _log('Removed reaction from message $messageId: $emoji');
  }

  /// Clears all cached messages.
  void clearCache() {
    _messages = [];
    _nextCursor = null;
    _hasMore = false;
    _isOfflineData = false;
    _log('Cache cleared');
  }

  /// Syncs the cache with external messages and pagination state (for tests or state recovery).
  void syncMessages(List<Message> messages, {int? nextCursor, bool? hasMore}) {
    _messages = List.from(messages);
    if (nextCursor != null) _nextCursor = nextCursor;
    if (hasMore != null) _hasMore = hasMore;
    _log('Synced ${messages.length} messages (cursor=$nextCursor, hasMore=$hasMore)');
  }

  // ============================================================
  // Pending Message Management (낙관적 UI용)
  // ============================================================

  /// Adds a pending message to the cache (optimistic UI).
  void addPendingMessage(Message message) {
    _messages = [message, ..._messages];
    _log('Added pending message: localId=${message.localId}');
  }

  /// Updates a pending message's send status.
  void updatePendingMessageStatus(String localId, MessageSendStatus status) {
    _messages = _messages.map((m) {
      if (m.localId == localId) {
        _log('Updated pending message status: localId=$localId, status=$status');
        return m.copyWith(sendStatus: status);
      }
      return m;
    }).toList();
  }

  /// Replaces a pending message with the real message from server.
  /// Returns true if a pending message was found and replaced.
  ///
  /// Matching criteria:
  /// - Same content
  /// - Created within 60 seconds of the real message
  /// - If multiple matches, select the OLDEST one (FIFO)
  bool replacePendingMessageWithReal(String content, Message realMessage) {
    // Find all pending messages with matching content within time window
    final matchingIndices = <int>[];
    const maxTimeDiff = Duration(seconds: 60);

    for (int i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.isPending && m.content == content) {
        final timeDiff = realMessage.createdAt.difference(m.createdAt).abs();
        if (timeDiff <= maxTimeDiff) {
          matchingIndices.add(i);
        }
      }
    }

    if (matchingIndices.isEmpty) {
      return false;
    }

    // Select the OLDEST matching pending message (FIFO ordering)
    // Since messages are added at the beginning, the oldest is at the highest index
    final pendingIndex = matchingIndices.reduce((a, b) => a > b ? a : b);
    final pendingMessage = _messages[pendingIndex];

    _log('Replacing pending message (localId=${pendingMessage.localId}) with real message (id=${realMessage.id})');
    // Create new list for Equatable compatibility
    _messages = [
      for (int i = 0; i < _messages.length; i++)
        if (i == pendingIndex)
          realMessage.copyWith(sendStatus: MessageSendStatus.sent)
        else
          _messages[i],
    ];
    return true;
  }

  /// Removes a pending message by localId.
  void removePendingMessage(String localId) {
    _messages = _messages.where((m) => m.localId != localId).toList();
    _log('Removed pending message: localId=$localId');
  }

  /// Gets a pending message by localId.
  Message? getPendingMessage(String localId) {
    try {
      return _messages.firstWhere((m) => m.localId == localId);
    } catch (_) {
      return null;
    }
  }

  /// Gets the last message ID in the cache (excluding pending messages).
  int? get lastMessageId {
    final realMessages = _messages.where((m) => !m.isPending && !m.isFailed);
    return realMessages.isNotEmpty ? realMessages.first.id : null;
  }

  /// Marks pending messages as failed if they exceed the timeout.
  /// Returns the list of localIds that were timed out.
  List<String> timeoutPendingMessages({Duration timeout = const Duration(seconds: 30)}) {
    final now = DateTime.now();
    final timedOutLocalIds = <String>[];

    _messages = _messages.map((m) {
      if (m.isPending && m.localId != null) {
        final elapsed = now.difference(m.createdAt);
        if (elapsed > timeout) {
          _log('Pending message timed out: localId=${m.localId}, elapsed=${elapsed.inSeconds}s');
          timedOutLocalIds.add(m.localId!);
          return m.copyWith(sendStatus: MessageSendStatus.failed);
        }
      }
      return m;
    }).toList();

    return timedOutLocalIds;
  }

  /// Gets all pending messages.
  List<Message> get pendingMessages => _messages.where((m) => m.isPending).toList();

  List<Message> get messages => _messages;
  int? get nextCursor => _nextCursor;
  bool get hasMore => _hasMore;
  bool get isOfflineData => _isOfflineData;
}
