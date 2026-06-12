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
  /// Fetches the latest page of messages from server (no cursor = newest),
  /// then MERGES it into the existing cache instead of replacing it. This is
  /// critical: the server only returns one page (size=[messagePageSize]), so a
  /// naive replacement would drop any older pages the user already loaded by
  /// scrolling up ([loadMoreMessages]). The merge preserves those older
  /// messages (real messages whose id is below the server page's minimum id),
  /// the server's latest page, and unresolved pending messages.
  ///
  /// Deduplicates by message ID, keeps the sort invariant (pending-front +
  /// id desc), and returns whether genuinely new server messages were found.
  ///
  /// Note: if the server's latest page does not overlap the existing cache's
  /// newest real message (a true mid-history gap), the older messages are still
  /// preserved here; fetching the in-between slice is intentionally left out to
  /// avoid extra requests on every foreground — pagination already covers it.
  Future<bool> refreshFromServer(int roomId) async {
    try {
      final (serverMessages, nextCursor, hasMore) =
          await _chatRepository.getMessages(
        roomId,
        size: AppConstants.messagePageSize,
      );

      _log('refreshFromServer: fetched ${serverMessages.length} messages');

      if (serverMessages.isEmpty) return false;

      // Preserve locally-originated messages that are NOT yet on the server.
      // A locally-originated message (negative ID) is considered "resolved" if
      // a server message with the same content exists within a 60-second window.
      final localMsgs =
          _messages.where((m) => m.id < 0).toList();

      // Real (server-confirmed) messages already in the cache, including any
      // older pages loaded via pagination.
      final existingReal = _messages.where((m) => m.id > 0).toList();

      // Merge: use server messages as the base, deduplicate
      final serverIds = serverMessages.map((m) => m.id).toSet();
      final existingIds = existingReal.map((m) => m.id).toSet();

      // Check if there are genuinely new messages
      final hasNewMessages = serverIds.any((id) => !existingIds.contains(id));

      // Resolve local messages that match server messages (prevent duplicates)
      // Must match sender too: don't resolve my local msg with another user's msg
      const maxTimeDiff = Duration(seconds: 60);
      final resolvedLocalIds = <String>{};
      for (final local in localMsgs) {
        for (final server in serverMessages) {
          if (local.senderId == server.senderId &&
              local.content == server.content &&
              server.createdAt.difference(local.createdAt).abs() <= maxTimeDiff) {
            if (local.localId != null) resolvedLocalIds.add(local.localId!);
            _log('refreshFromServer: resolved local message (localId=${local.localId}) with server message (id=${server.id})');
            break;
          }
        }
      }

      // Keep only unresolved local messages (failed ones that weren't sent)
      final unresolvedLocals = localMsgs
          .where((m) => m.localId == null || !resolvedLocalIds.contains(m.localId!))
          .toList();

      // Preserve older real messages that the server's latest page does not
      // contain (i.e. older pages loaded by scrolling up). These have ids
      // smaller than the page's minimum id; server data wins for overlap.
      final olderPreserved = existingReal
          .where((m) => !serverIds.contains(m.id))
          .toList();

      // Build merged list: unresolved locals first, then server's latest page,
      // then preserved older real messages.
      _messages = [...unresolvedLocals, ...serverMessages, ...olderPreserved];

      // Deduplicate by id (keep first occurrence)
      final seenIds = <int>{};
      _messages = _messages.where((m) {
        if (m.id < 0) return true; // always keep local messages
        if (seenIds.contains(m.id)) return false;
        seenIds.add(m.id);
        return true;
      }).toList();

      // Ensure consistent ordering: pending first, then real messages by ID descending
      _sortMessages();

      // Pagination state: only adopt the server page's cursor/hasMore when no
      // older messages were preserved. If we kept older pages, overwriting the
      // cursor with the server page's (newer) cursor would break the page
      // boundary and let pagination re-fetch already-loaded messages — so keep
      // the existing cursor/hasMore that still point past the oldest message.
      if (olderPreserved.isEmpty) {
        _nextCursor = nextCursor;
        _hasMore = hasMore;
      } else {
        _log('refreshFromServer: preserved ${olderPreserved.length} older messages, keeping existing pagination cursor');
      }
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

  /// Adds a new message to the cache in sorted position (ID descending).
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
      // Insert at the correct sorted position (ID descending, pending first)
      final insertIndex = _findSortedInsertIndex(message);
      _messages = [
        ..._messages.sublist(0, insertIndex),
        message,
        ..._messages.sublist(insertIndex),
      ];
      _log('Added new message: id=${message.id} at index=$insertIndex');
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

  /// Replaces a locally-originated message with the real message from server.
  /// Returns true if a local message was found and replaced.
  ///
  /// Matches locally-originated messages (negative ID) regardless of send status
  /// (pending or already marked as sent). This handles:
  /// - pending messages waiting for echo
  /// - messages already marked as "sent" via fire-and-forget
  ///
  /// Matching criteria:
  /// - Locally originated (negative ID)
  /// - Same content
  /// - Created within 60 seconds of the real message
  /// - If multiple matches, select the OLDEST one (FIFO)
  bool replacePendingMessageWithReal(String content, Message realMessage) {
    final matchingIndices = <int>[];
    const maxTimeDiff = Duration(seconds: 60);

    for (int i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      // Match locally-originated messages (negative temp ID) with same content
      if (m.id < 0 && m.content == content) {
        final timeDiff = realMessage.createdAt.difference(m.createdAt).abs();
        if (timeDiff <= maxTimeDiff) {
          matchingIndices.add(i);
        }
      }
    }

    if (matchingIndices.isEmpty) {
      return false;
    }

    // Select the OLDEST matching local message (FIFO ordering)
    // Since messages are added at the beginning, the oldest is at the highest index
    final localIndex = matchingIndices.reduce((a, b) => a > b ? a : b);
    final localMessage = _messages[localIndex];

    _log('Replacing local message (localId=${localMessage.localId}) with real message (id=${realMessage.id})');
    // Preserve reply/forward metadata from local message if server didn't return it.
    // Also preserve localId so that _keyOf() in message_list.dart returns the same
    // key before and after confirmation — prevents the bubble from animating a second time.
    final mergedMessage = realMessage.copyWith(
      sendStatus: MessageSendStatus.sent,
      localId: localMessage.localId,
      replyToMessage: realMessage.replyToMessage ?? localMessage.replyToMessage,
      replyToMessageId: realMessage.replyToMessageId ?? localMessage.replyToMessageId,
      forwardedFromMessageId: realMessage.forwardedFromMessageId ?? localMessage.forwardedFromMessageId,
    );
    // Remove the pending message and re-insert at the correct sorted position
    _messages = [
      for (int i = 0; i < _messages.length; i++)
        if (i != localIndex) _messages[i],
    ];
    final insertIndex = _findSortedInsertIndex(mergedMessage);
    _messages = [
      ..._messages.sublist(0, insertIndex),
      mergedMessage,
      ..._messages.sublist(insertIndex),
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

  // ============================================================
  // Message Ordering
  // ============================================================

  /// Finds the correct insertion index for a message in a sorted list.
  ///
  /// List invariant: pending messages (id < 0) first, then real messages
  /// in descending ID order (newest first).
  int _findSortedInsertIndex(Message message) {
    // Pending messages always go to the front
    if (message.id < 0) return 0;

    // For real messages, skip past pending messages and find position by ID descending
    for (int i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.id < 0) continue; // skip pending messages
      if (m.id < message.id) return i; // insert before the first smaller ID
    }
    return _messages.length; // smallest ID → add at end
  }

  /// Sorts the entire message list: pending first, then real messages by ID descending.
  void _sortMessages() {
    _messages.sort((a, b) {
      // Pending messages (negative IDs) always come first
      if (a.id < 0 && b.id >= 0) return -1;
      if (a.id >= 0 && b.id < 0) return 1;
      // Both pending: sort by createdAt descending (newest first)
      if (a.id < 0 && b.id < 0) return b.createdAt.compareTo(a.createdAt);
      // Both real: sort by ID descending (newest first)
      return b.id.compareTo(a.id);
    });
  }
}
