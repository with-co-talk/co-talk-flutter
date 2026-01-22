import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/remote/friend_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/friend_model.dart';
import 'package:co_talk_flutter/data/models/user_model.dart';
import 'package:co_talk_flutter/data/repositories/friend_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

class MockFriendRemoteDataSource extends Mock implements FriendRemoteDataSource {}

void main() {
  late MockFriendRemoteDataSource mockRemoteDataSource;
  late FriendRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockFriendRemoteDataSource();
    repository = FriendRepositoryImpl(mockRemoteDataSource);
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
      test('returns friends successfully', () async {
        when(() => mockRemoteDataSource.getFriends())
            .thenAnswer((_) async => [testFriendModel]);

        final result = await repository.getFriends();

        expect(result, isA<List<Friend>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        verify(() => mockRemoteDataSource.getFriends()).called(1);
      });

      test('returns empty list when no friends', () async {
        when(() => mockRemoteDataSource.getFriends())
            .thenAnswer((_) async => []);

        final result = await repository.getFriends();

        expect(result, isEmpty);
      });

      test('throws exception when request fails', () async {
        when(() => mockRemoteDataSource.getFriends())
            .thenThrow(Exception('Failed to load friends'));

        expect(
          () => repository.getFriends(),
          throwsException,
        );
      });
    });

    group('sendFriendRequest', () {
      test('sends friend request successfully', () async {
        when(() => mockRemoteDataSource.sendFriendRequest(any()))
            .thenAnswer((_) async {});

        await repository.sendFriendRequest(2);

        verify(() => mockRemoteDataSource.sendFriendRequest(2)).called(1);
      });

      test('throws exception when request fails', () async {
        when(() => mockRemoteDataSource.sendFriendRequest(any()))
            .thenThrow(Exception('Already sent request'));

        expect(
          () => repository.sendFriendRequest(2),
          throwsException,
        );
      });
    });

    group('acceptFriendRequest', () {
      test('accepts friend request successfully', () async {
        when(() => mockRemoteDataSource.acceptFriendRequest(any()))
            .thenAnswer((_) async {});

        await repository.acceptFriendRequest(1);

        verify(() => mockRemoteDataSource.acceptFriendRequest(1)).called(1);
      });

      test('throws exception when request fails', () async {
        when(() => mockRemoteDataSource.acceptFriendRequest(any()))
            .thenThrow(Exception('Request not found'));

        expect(
          () => repository.acceptFriendRequest(1),
          throwsException,
        );
      });
    });

    group('rejectFriendRequest', () {
      test('rejects friend request successfully', () async {
        when(() => mockRemoteDataSource.rejectFriendRequest(any()))
            .thenAnswer((_) async {});

        await repository.rejectFriendRequest(1);

        verify(() => mockRemoteDataSource.rejectFriendRequest(1)).called(1);
      });

      test('throws exception when request fails', () async {
        when(() => mockRemoteDataSource.rejectFriendRequest(any()))
            .thenThrow(Exception('Request not found'));

        expect(
          () => repository.rejectFriendRequest(1),
          throwsException,
        );
      });
    });

    group('removeFriend', () {
      test('removes friend successfully', () async {
        when(() => mockRemoteDataSource.removeFriend(any()))
            .thenAnswer((_) async {});

        await repository.removeFriend(2);

        verify(() => mockRemoteDataSource.removeFriend(2)).called(1);
      });

      test('throws exception when request fails', () async {
        when(() => mockRemoteDataSource.removeFriend(any()))
            .thenThrow(Exception('Friend not found'));

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

    group('getReceivedFriendRequests', () {
      test('returns received friend requests successfully', () async {
        when(() => mockRemoteDataSource.getReceivedFriendRequests())
            .thenAnswer((_) async => []);

        final result = await repository.getReceivedFriendRequests();

        expect(result, isA<List<FriendRequest>>());
        verify(() => mockRemoteDataSource.getReceivedFriendRequests()).called(1);
      });
    });

    group('getSentFriendRequests', () {
      test('returns sent friend requests successfully', () async {
        when(() => mockRemoteDataSource.getSentFriendRequests())
            .thenAnswer((_) async => []);

        final result = await repository.getSentFriendRequests();

        expect(result, isA<List<FriendRequest>>());
        verify(() => mockRemoteDataSource.getSentFriendRequests()).called(1);
      });
    });
  });
}
