import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/models/user_model.dart';
import 'package:co_talk_flutter/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    test('creates model with required fields', () {
      final model = UserModel(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.id, 1);
      expect(model.email, 'test@example.com');
      expect(model.nickname, 'TestUser');
    });

    test('creates model with all fields', () {
      final model = UserModel(
        id: 1,
        email: 'test@example.com',
        nickname: 'TestUser',
        avatarUrl: 'https://example.com/avatar.jpg',
        status: 'ACTIVE',
        role: 'ADMIN',
        onlineStatus: 'ONLINE',
        lastActiveAt: DateTime(2024, 1, 1, 10, 0),
        createdAt: DateTime(2024, 1, 1),
      );

      expect(model.avatarUrl, 'https://example.com/avatar.jpg');
      expect(model.status, 'ACTIVE');
      expect(model.role, 'ADMIN');
      expect(model.onlineStatus, 'ONLINE');
    });

    group('toEntity', () {
      test('converts to User entity with default values', () {
        final model = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          createdAt: DateTime(2024, 1, 1),
        );

        final entity = model.toEntity();

        expect(entity, isA<User>());
        expect(entity.id, 1);
        expect(entity.email, 'test@example.com');
        expect(entity.nickname, 'TestUser');
        expect(entity.status, UserStatus.active);
        expect(entity.role, UserRole.user);
        expect(entity.onlineStatus, OnlineStatus.offline);
      });

      test('converts status correctly', () {
        final activeModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          status: 'ACTIVE',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(activeModel.toEntity().status, UserStatus.active);

        final inactiveModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          status: 'INACTIVE',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(inactiveModel.toEntity().status, UserStatus.inactive);

        final suspendedModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          status: 'SUSPENDED',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(suspendedModel.toEntity().status, UserStatus.suspended);
      });

      test('converts role correctly', () {
        final adminModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          role: 'ADMIN',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(adminModel.toEntity().role, UserRole.admin);

        final userModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          role: 'USER',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(userModel.toEntity().role, UserRole.user);
      });

      test('converts online status correctly', () {
        final onlineModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          onlineStatus: 'ONLINE',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(onlineModel.toEntity().onlineStatus, OnlineStatus.online);

        final awayModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          onlineStatus: 'AWAY',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(awayModel.toEntity().onlineStatus, OnlineStatus.away);

        final offlineModel = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          onlineStatus: 'OFFLINE',
          createdAt: DateTime(2024, 1, 1),
        );
        expect(offlineModel.toEntity().onlineStatus, OnlineStatus.offline);
      });
    });

    group('fromJson', () {
      test('creates model from JSON', () {
        final json = {
          'id': 1,
          'email': 'test@example.com',
          'nickname': 'TestUser',
          'createdAt': '2024-01-01T00:00:00.000',
        };

        final model = UserModel.fromJson(json);

        expect(model.id, 1);
        expect(model.email, 'test@example.com');
        expect(model.nickname, 'TestUser');
      });
    });

    group('toJson', () {
      test('converts model to JSON', () {
        final model = UserModel(
          id: 1,
          email: 'test@example.com',
          nickname: 'TestUser',
          createdAt: DateTime(2024, 1, 1),
        );

        final json = model.toJson();

        expect(json['id'], 1);
        expect(json['email'], 'test@example.com');
        expect(json['nickname'], 'TestUser');
      });
    });
  });
}
