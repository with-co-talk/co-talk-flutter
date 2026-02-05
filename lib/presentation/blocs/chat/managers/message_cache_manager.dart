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

      _messages = [..._messages, ...messages];
      _nextCursor = nextCursor;
      _hasMore = hasMore;

      _log('Loaded ${messages.length} more messages. Total: ${_messages.length}');
      return _messages;
    } catch (e) {
      _log('Failed to load more messages: $e');
      rethrow;
    }
  }

  /// Adds a new message to the cache.
  Future<void> addMessage(Message message) async {
    // Check if message already exists
    final existingIndex = _messages.indexWhere((m) => m.id == message.id);

    if (existingIndex != -1) {
      // Update existing message
      _messages[existingIndex] = message;
      _log('Updated existing message: id=${message.id}');
    } else {
      // Add new message at the beginning
      _messages = [message, ..._messages];
      _log('Added new message: id=${message.id}');
    }

    // Save to local cache
    try {
      await _chatRepository.saveMessageLocally(message);
    } catch (e) {
      _log('Failed to save message locally: $e');
    }

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

  /// Clears all cached messages.
  void clearCache() {
    _messages = [];
    _nextCursor = null;
    _hasMore = false;
    _isOfflineData = false;
    _log('Cache cleared');
  }

  /// Gets the last message ID in the cache.
  int? get lastMessageId => _messages.isNotEmpty ? _messages.first.id : null;

  List<Message> get messages => _messages;
  int? get nextCursor => _nextCursor;
  bool get hasMore => _hasMore;
  bool get isOfflineData => _isOfflineData;
}
