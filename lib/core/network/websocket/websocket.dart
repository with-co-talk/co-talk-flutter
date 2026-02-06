/// WebSocket module for real-time chat communication.
///
/// This module provides a modular WebSocket implementation following
/// Clean Architecture principles.
///
/// Components:
/// - [WebSocketConfig]: Configuration settings
/// - [WebSocketConnectionManager]: Connection lifecycle management
/// - [WebSocketSubscriptionManager]: Topic subscription management
/// - [WebSocketMessageSender]: Message sending utilities
/// - [WebSocketPayloadParser]: JSON payload parsing
/// - [WebSocketService]: Facade that composes all components
///
/// Event models:
/// - [WebSocketChatMessage]: Chat message event
/// - [WebSocketReactionEvent]: Reaction add/remove event
/// - [WebSocketReadEvent]: Read receipt event
/// - [WebSocketChatRoomUpdateEvent]: Chat room list update event
/// - [WebSocketTypingEvent]: Typing indicator event
/// - [WebSocketOnlineStatusEvent]: Online status event
/// - [WebSocketMessageDeletedEvent]: Message deletion event
/// - [WebSocketProfileUpdateEvent]: Profile update event
library;

export 'websocket_config.dart';
export 'websocket_connection_manager.dart';
export 'websocket_event_parser.dart';
export 'websocket_events.dart';
export 'websocket_message_sender.dart';
export 'websocket_subscription_manager.dart';
