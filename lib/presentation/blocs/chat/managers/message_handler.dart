import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../data/datasources/local/auth_local_datasource.dart';
import '../../../../domain/entities/message.dart';
import '../../../../domain/repositories/chat_repository.dart';

/// Handles message operations.
///
/// Handles:
/// - Message sending
/// - Message editing
/// - Message deletion
/// - File attachments
/// - Message reactions
class MessageHandler {
  final ChatRepository _chatRepository;
  final WebSocketService _webSocketService;
  final AuthLocalDataSource _authLocalDataSource;

  MessageHandler(
    this._chatRepository,
    this._webSocketService,
    this._authLocalDataSource,
  );

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[MessageHandler] $message');
    }
  }

  /// Sends a text message.
  ///
  /// Pass [userId] from BLoC state to avoid an async storage read on every send.
  /// Throws an exception if the message fails to send (e.g., WebSocket not connected).
  ///
  /// If the first send attempt fails (e.g., STOMP connection dropped between
  /// the isConnected check and the actual send), retries once after reconnecting.
  Future<void> sendMessage({
    required int roomId,
    required String content,
    int? userId,
  }) async {
    if (userId == null) {
      userId = await _authLocalDataSource.getUserId();
      if (userId == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }
    }

    _log('Sending message: roomId=$roomId, isConnected=${_webSocketService.isConnected}');

    // 연결이 안 되어 있으면 재연결 시도
    if (!_webSocketService.isConnected) {
      _log('WebSocket not connected, attempting to reconnect...');
      final connected = await _webSocketService.ensureConnected(
        timeout: const Duration(seconds: 10),
      );
      if (!connected) {
        _log('Failed to reconnect WebSocket');
        throw Exception('메시지 전송에 실패했습니다. 네트워크 연결을 확인해주세요.');
      }
      _log('WebSocket reconnected successfully');
    }

    var success = _webSocketService.sendMessage(
      roomId: roomId,
      content: content,
    );

    // Retry once: the STOMP connection may have dropped between isConnected
    // check and the actual send (stale stompClient.connected state).
    if (!success) {
      _log('First send attempt failed, retrying after ensureConnected...');
      final reconnected = await _webSocketService.ensureConnected(
        timeout: const Duration(seconds: 10),
      );
      if (reconnected) {
        success = _webSocketService.sendMessage(
          roomId: roomId,
          content: content,
        );
      }
      if (!success) {
        _log('Retry also failed, giving up');
        throw Exception('메시지 전송에 실패했습니다. 네트워크 연결을 확인해주세요.');
      }
      _log('Message sent successfully on retry');
      return;
    }

    _log('Message sent successfully');
  }

  /// Updates an existing message.
  Future<Message> updateMessage({
    required int messageId,
    required String content,
  }) async {
    try {
      final updatedMessage = await _chatRepository.updateMessage(
        messageId,
        content,
      );
      _log('Message updated: id=$messageId');
      return updatedMessage;
    } catch (e) {
      _log('Failed to update message: $e');
      rethrow;
    }
  }

  /// Deletes a message.
  Future<void> deleteMessage(int messageId) async {
    try {
      await _chatRepository.deleteMessage(messageId);
      _log('Message deleted: id=$messageId');
    } catch (e) {
      _log('Failed to delete message: $e');
      rethrow;
    }
  }

  /// Marks messages as read.
  Future<void> markAsRead(int roomId) async {
    try {
      await _chatRepository.markAsRead(roomId);
      _log('Marked as read: roomId=$roomId');
    } catch (e) {
      _log('Failed to mark as read: $e');
    }
  }

  /// Handles file attachment and upload.
  Future<FileUploadResult> handleFileAttachment({
    required int roomId,
    required String filePath,
    required Function(double) onProgress,
  }) async {
    _log('handleFileAttachment: filePath=$filePath');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('파일을 찾을 수 없습니다');
    }

    final fileSize = await file.length();
    if (fileSize > AppConstants.maxFileSize) {
      throw Exception(
        '파일 크기는 ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB 이하여야 합니다',
      );
    }

    onProgress(0.0);

    try {
      final uploadResult = await _chatRepository.uploadFile(file);
      _log('File uploaded: ${uploadResult.fileUrl}');

      onProgress(0.5);

      await _chatRepository.sendFileMessage(
        roomId: roomId,
        fileUrl: uploadResult.fileUrl,
        fileName: uploadResult.fileName,
        fileSize: uploadResult.fileSize,
        contentType: uploadResult.contentType,
        thumbnailUrl: uploadResult.isImage ? uploadResult.fileUrl : null,
      );

      onProgress(1.0);
      return uploadResult;
    } catch (e) {
      _log('File attachment failed: $e');
      rethrow;
    }
  }

  /// Leaves a chat room.
  Future<void> leaveChatRoom(int roomId) async {
    try {
      await _chatRepository.leaveChatRoom(roomId);
      _log('Left chat room: roomId=$roomId');
    } catch (e) {
      _log('Failed to leave chat room: $e');
      rethrow;
    }
  }

  /// Reinvites a user to the chat room.
  Future<void> reinviteUser({
    required int roomId,
    required int inviteeId,
  }) async {
    try {
      await _chatRepository.reinviteUser(roomId, inviteeId);
      _log('User reinvited: roomId=$roomId, inviteeId=$inviteeId');
    } catch (e) {
      _log('Failed to reinvite user: $e');
      rethrow;
    }
  }
}
