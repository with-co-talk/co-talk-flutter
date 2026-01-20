import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';
import 'package:co_talk_flutter/data/datasources/remote/friend_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/friend_model.dart';
import 'package:co_talk_flutter/data/models/user_model.dart';
import 'package:co_talk_flutter/data/repositories/friend_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

class MockFriendRemoteDataSource extends Mock implements FriendRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockFriendRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late FriendRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockFriendRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = FriendRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);
  });

  final testUserModel = UserModel(
    id: 2,
    email: 'friend@example.com',
    nickname: 'FriendUser',
    createdAt: DateTime(2024, 1, 1),
  );

  final testFriendModel = FriendModel(
    id: 1,
    user: testUserModel,
    createdAt: DateTime(2024, 1, 1),
  );

  group('FriendRepository', () {
    group('getFriends', () {
      test('returns friends when user is logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.getFriends(any()))
            .thenAnswer((_) async => [testFriendModel]);

        final result = await repository.getFriends();

        expect(result, isA<List<Friend>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        verify(() => mockRemoteDataSource.getFriends(1)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.getFriends(),
          throwsException,
        );
      });

      test('returns empty list when no friends', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.getFriends(any()))
            .thenAnswer((_) async => []);

        final result = await repository.getFriends();

        expect(result, isEmpty);
      });
    });

    group('sendFriendRequest', () {
      test('sends friend request successfully', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.sendFriendRequest(any(), any()))
            .thenAnswer((_) async {});

        await repository.sendFriendRequest(2);

        verify(() => mockRemoteDataSource.sendFriendRequest(1, 2)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.sendFriendRequest(2),
          throwsException,
        );
      });

      test('throws exception when request fails', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.sendFriendRequest(any(), any()))
            .thenThrow(Exception('Already sent request'));

        expect(
          () => repository.sendFriendRequest(2),
          throwsException,
        );
      });
    });

    group('acceptFriendRequest', () {
      test('accepts friend request successfully', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.acceptFriendRequest(any(), any()))
            .thenAnswer((_) async {});

        await repository.acceptFriendRequest(1);

        verify(() => mockRemoteDataSource.acceptFriendRequest(1, 1)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.acceptFriendRequest(1),
          throwsException,
        );
      });
    });

    group('rejectFriendRequest', () {
      test('rejects friend request successfully', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.rejectFriendRequest(any(), any()))
            .thenAnswer((_) async {});

        await repository.rejectFriendRequest(1);

        verify(() => mockRemoteDataSource.rejectFriendRequest(1, 1)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.rejectFriendRequest(1),
          throwsException,
        );
      });
    });

    group('removeFriend', () {
      test('removes friend successfully', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => 1);
        when(() => mockRemoteDataSource.removeFriend(any(), any()))
            .thenAnswer((_) async {});

        await repository.removeFriend(2);

        verify(() => mockRemoteDataSource.removeFriend(1, 2)).called(1);
      });

      test('throws exception when user is not logged in', () async {
        when(() => mockLocalDataSource.getUserId())
            .thenAnswer((_) async => null);

        expect(
          () => repository.removeFriend(2),
          throwsException,
        );
      });
    });

    group('searchUsers', () {
      test('returns users matching query', () async {
        when(() => mockRemoteDataSource.searchUsers(any()))
            .thenAnswer((_) async => [testUserModel]);

        final result = await repository.searchUsers('test');

        expect(result, isA<List<User>>());
        expect(result.length, 1);
        expect(result.first.nickname, 'FriendUser');
        verify(() => mockRemoteDataSource.searchUsers('test')).called(1);
      });

      test('returns empty list when no matches', () async {
        when(() => mockRemoteDataSource.searchUsers(any()))
            .thenAnswer((_) async => []);

        final result = await repository.searchUsers('nonexistent');

        expect(result, isEmpty);
      });

      test('throws exception when search fails', () async {
        when(() => mockRemoteDataSource.searchUsers(any()))
            .thenThrow(Exception('Search failed'));

        expect(
          () => repository.searchUsers('test'),
          throwsException,
        );
      });
    });
  });
}
