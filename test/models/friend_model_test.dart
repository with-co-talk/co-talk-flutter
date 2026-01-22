import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/models/friend_model.dart';
import 'package:co_talk_flutter/data/models/user_model.dart';
import 'package:co_talk_flutter/domain/entities/friend.dart';

void main() {
  final testUserModel = UserModel(
    id: 1,
    email: 'test@example.com',
    nickname: 'TestUser',
    createdAt: DateTime(2024, 1, 1),
  );

  final testUserModel2 = UserModel(
    id: 2,
    email: 'user2@example.com',
    nickname: 'User2',
    createdAt: DateTime(2024, 1, 1),
  );

  group('FriendModel', () {
    test('creates model with required fields', () {
      final model = FriendModel(
        id: 1,
        user: testUserModel,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.id, 1);
      expect(model.user, testUserModel);
      expect(model.createdAt, DateTime(2024, 1, 1));
    });

    group('toEntity', () {
      test('converts to Friend entity', () {
        final model = FriendModel(
          id: 1,
          user: testUserModel,
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();

        expect(entity, isA<Friend>());
        expect(entity.id, 1);
        expect(entity.user.nickname, 'TestUser');
      });
    });

    test('toJson returns correct map', () {
      final model = FriendModel(
        id: 1,
        user: testUserModel,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['user'], isNotNull);
    });
  });

  group('FriendRequestModel', () {
    test('creates model with required fields', () {
      final model = FriendRequestModel(
        id: 1,
        requester: testUserModel,
        receiver: testUserModel2,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.id, 1);
      expect(model.requester, testUserModel);
      expect(model.receiver, testUserModel2);
      expect(model.status, isNull);
    });

    test('creates model with status', () {
      final model = FriendRequestModel(
        id: 1,
        requester: testUserModel,
        receiver: testUserModel2,
        status: 'PENDING',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.status, 'PENDING');
    });

    group('toEntity', () {
      test('converts to FriendRequest entity', () {
        final model = FriendRequestModel(
          id: 1,
          requester: testUserModel,
          receiver: testUserModel2,
          status: 'PENDING',
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();

        expect(entity, isA<FriendRequest>());
        expect(entity.id, 1);
        expect(entity.requester.nickname, 'TestUser');
        expect(entity.receiver.nickname, 'User2');
        expect(entity.status, FriendRequestStatus.pending);
      });

      test('converts ACCEPTED status correctly', () {
        final model = FriendRequestModel(
          id: 1,
          requester: testUserModel,
          receiver: testUserModel2,
          status: 'ACCEPTED',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().status, FriendRequestStatus.accepted);
      });

      test('converts REJECTED status correctly', () {
        final model = FriendRequestModel(
          id: 1,
          requester: testUserModel,
          receiver: testUserModel2,
          status: 'REJECTED',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().status, FriendRequestStatus.rejected);
      });

      test('handles null status as pending', () {
        final model = FriendRequestModel(
          id: 1,
          requester: testUserModel,
          receiver: testUserModel2,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().status, FriendRequestStatus.pending);
      });

      test('handles unknown status as pending', () {
        final model = FriendRequestModel(
          id: 1,
          requester: testUserModel,
          receiver: testUserModel2,
          status: 'UNKNOWN',
          createdAt: DateTime(2024, 1, 1),
        );

        expect(model.toEntity().status, FriendRequestStatus.pending);
      });
    });

    test('toJson returns correct map', () {
      final model = FriendRequestModel(
        id: 1,
        requester: testUserModel,
        receiver: testUserModel2,
        status: 'PENDING',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = model.toJson();

      expect(json['id'], 1);
      expect(json['status'], 'PENDING');
    });
  });

  group('SendFriendRequestRequest', () {
    test('creates request with required fields', () {
      const request = SendFriendRequestRequest(
        requesterId: 1,
        receiverId: 2,
      );

      expect(request.requesterId, 1);
      expect(request.receiverId, 2);
    });

    test('toJson returns correct map', () {
      const request = SendFriendRequestRequest(
        requesterId: 1,
        receiverId: 2,
      );

      final json = request.toJson();

      expect(json['requesterId'], 1);
      expect(json['receiverId'], 2);
    });
  });

  group('FriendListResponse', () {
    test('creates response with friends', () {
      final friend = FriendModel(
        id: 1,
        user: testUserModel,
        createdAt: DateTime(2024, 1, 1),
      );

      final response = FriendListResponse(friends: [friend]);

      expect(response.friends.length, 1);
      expect(response.friends.first.id, 1);
    });

    test('toJson returns correct map', () {
      final response = FriendListResponse(friends: []);

      final json = response.toJson();

      expect(json['friends'], isA<List>());
    });

    test('fromJson creates response correctly', () {
      final json = {
        'friends': [
          {
            'id': 1,
            'user': {
              'id': 1,
              'email': 'test@test.com',
              'nickname': 'Test',
              'createdAt': '2024-01-01T00:00:00.000',
            },
            'createdAt': '2024-01-01T00:00:00.000',
          }
        ]
      };

      final response = FriendListResponse.fromJson(json);

      expect(response.friends.length, 1);
      expect(response.friends.first.id, 1);
    });
  });

  group('FriendModel fromJson', () {
    test('parses json correctly', () {
      final json = {
        'id': 1,
        'user': {
          'id': 1,
          'email': 'test@test.com',
          'nickname': 'TestUser',
          'createdAt': '2024-01-01T00:00:00.000',
        },
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final model = FriendModel.fromJson(json);

      expect(model.id, 1);
      expect(model.user.nickname, 'TestUser');
    });
  });

  group('FriendRequestModel fromJson', () {
    test('parses json correctly', () {
      final json = {
        'id': 1,
        'requester': {
          'id': 1,
          'email': 'requester@test.com',
          'nickname': 'Requester',
          'createdAt': '2024-01-01T00:00:00.000',
        },
        'receiver': {
          'id': 2,
          'email': 'receiver@test.com',
          'nickname': 'Receiver',
          'createdAt': '2024-01-01T00:00:00.000',
        },
        'status': 'PENDING',
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final model = FriendRequestModel.fromJson(json);

      expect(model.id, 1);
      expect(model.requester.nickname, 'Requester');
      expect(model.receiver.nickname, 'Receiver');
      expect(model.status, 'PENDING');
    });
  });

  group('SendFriendRequestRequest fromJson', () {
    test('parses json correctly', () {
      final json = {
        'requesterId': 1,
        'receiverId': 2,
      };

      final request = SendFriendRequestRequest.fromJson(json);

      expect(request.requesterId, 1);
      expect(request.receiverId, 2);
    });
  });
}
