import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/network/websocket_service.dart';
import 'package:co_talk_flutter/core/services/active_room_tracker.dart';
import 'package:co_talk_flutter/core/services/desktop_notification_bridge.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';
import 'package:co_talk_flutter/domain/repositories/auth_repository.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';
import 'package:co_talk_flutter/domain/repositories/friend_repository.dart';
import 'package:co_talk_flutter/domain/repositories/notification_repository.dart';
import 'package:co_talk_flutter/domain/repositories/profile_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockFriendRepository extends Mock implements FriendRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockNotificationRepository extends Mock implements NotificationRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockDesktopNotificationBridge extends Mock implements DesktopNotificationBridge {}

class MockActiveRoomTracker extends Mock implements ActiveRoomTracker {}
