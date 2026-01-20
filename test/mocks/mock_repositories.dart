import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/repositories/auth_repository.dart';
import 'package:co_talk_flutter/domain/repositories/chat_repository.dart';
import 'package:co_talk_flutter/domain/repositories/friend_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockFriendRepository extends Mock implements FriendRepository {}
