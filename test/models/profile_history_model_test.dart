import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/models/profile_history_model.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';

void main() {
  group('ProfileHistoryModel', () {
    final testJson = {
      'id': 1,
      'userId': 100,
      'type': 'AVATAR',
      'url': 'https://example.com/avatar.jpg',
      'content': null,
      'isPrivate': false,
      'isCurrent': true,
      'createdAt': '2024-01-01T00:00:00.000Z',
    };

    final testModel = ProfileHistoryModel(
      id: 1,
      userId: 100,
      type: 'AVATAR',
      url: 'https://example.com/avatar.jpg',
      isPrivate: false,
      isCurrent: true,
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = ProfileHistoryModel.fromJson(testJson);

        expect(model.id, 1);
        expect(model.userId, 100);
        expect(model.type, 'AVATAR');
        expect(model.url, 'https://example.com/avatar.jpg');
        expect(model.content, isNull);
        expect(model.isPrivate, false);
        expect(model.isCurrent, true);
        expect(model.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 1,
          'userId': 100,
          'type': 'STATUS_MESSAGE',
          'url': null,
          'content': 'Hello world',
          'isPrivate': true,
          'isCurrent': false,
          'createdAt': '2024-01-01T00:00:00.000Z',
        };

        final model = ProfileHistoryModel.fromJson(json);

        expect(model.url, isNull);
        expect(model.content, 'Hello world');
        expect(model.isPrivate, true);
        expect(model.isCurrent, false);
      });

      test('should handle background type', () {
        final json = {
          'id': 1,
          'userId': 100,
          'type': 'BACKGROUND',
          'url': 'https://example.com/background.jpg',
          'isPrivate': false,
          'isCurrent': false,
          'createdAt': '2024-01-01T00:00:00.000Z',
        };

        final model = ProfileHistoryModel.fromJson(json);

        expect(model.type, 'BACKGROUND');
      });
    });

    group('toJson', () {
      test('should serialize correctly', () {
        final json = testModel.toJson();

        expect(json['id'], 1);
        expect(json['userId'], 100);
        expect(json['type'], 'AVATAR');
        expect(json['url'], 'https://example.com/avatar.jpg');
        expect(json['content'], isNull);
        expect(json['isPrivate'], false);
        expect(json['isCurrent'], true);
        expect(json['createdAt'], '2024-01-01T00:00:00.000Z');
      });

      test('should serialize with content field', () {
        final model = ProfileHistoryModel(
          id: 1,
          userId: 100,
          type: 'STATUS_MESSAGE',
          content: 'Hello world',
          isPrivate: false,
          isCurrent: false,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );

        final json = model.toJson();

        expect(json['content'], 'Hello world');
        expect(json['url'], isNull);
      });
    });

    group('toEntity', () {
      test('should convert to ProfileHistory entity correctly', () {
        final entity = testModel.toEntity();

        expect(entity, isA<ProfileHistory>());
        expect(entity.id, 1);
        expect(entity.userId, 100);
        expect(entity.type, ProfileHistoryType.avatar);
        expect(entity.url, 'https://example.com/avatar.jpg');
        expect(entity.content, isNull);
        expect(entity.isPrivate, false);
        expect(entity.isCurrent, true);
        expect(entity.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      });

      test('should convert background type correctly', () {
        final model = ProfileHistoryModel(
          id: 1,
          userId: 100,
          type: 'BACKGROUND',
          url: 'https://example.com/bg.jpg',
          isPrivate: false,
          isCurrent: false,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );

        final entity = model.toEntity();

        expect(entity.type, ProfileHistoryType.background);
      });

      test('should convert status message type correctly', () {
        final model = ProfileHistoryModel(
          id: 1,
          userId: 100,
          type: 'STATUS_MESSAGE',
          content: 'Hello',
          isPrivate: false,
          isCurrent: false,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );

        final entity = model.toEntity();

        expect(entity.type, ProfileHistoryType.statusMessage);
      });
    });

    group('typeToString', () {
      test('should convert avatar enum to API string', () {
        expect(
          ProfileHistoryModel.typeToString(ProfileHistoryType.avatar),
          'AVATAR',
        );
      });

      test('should convert background enum to API string', () {
        expect(
          ProfileHistoryModel.typeToString(ProfileHistoryType.background),
          'BACKGROUND',
        );
      });

      test('should convert statusMessage enum to API string', () {
        expect(
          ProfileHistoryModel.typeToString(ProfileHistoryType.statusMessage),
          'STATUS_MESSAGE',
        );
      });
    });

    group('_parseType', () {
      test('should handle AVATAR type string', () {
        final model = ProfileHistoryModel.fromJson({
          ...testJson,
          'type': 'AVATAR',
        });

        expect(model.toEntity().type, ProfileHistoryType.avatar);
      });

      test('should handle BACKGROUND type string', () {
        final model = ProfileHistoryModel.fromJson({
          ...testJson,
          'type': 'BACKGROUND',
        });

        expect(model.toEntity().type, ProfileHistoryType.background);
      });

      test('should handle STATUS_MESSAGE type string', () {
        final model = ProfileHistoryModel.fromJson({
          ...testJson,
          'type': 'STATUS_MESSAGE',
        });

        expect(model.toEntity().type, ProfileHistoryType.statusMessage);
      });

      test('should handle lowercase type strings', () {
        final model = ProfileHistoryModel.fromJson({
          ...testJson,
          'type': 'avatar',
        });

        expect(model.toEntity().type, ProfileHistoryType.avatar);
      });

      test('should handle unknown type gracefully', () {
        final model = ProfileHistoryModel.fromJson({
          ...testJson,
          'type': 'UNKNOWN_TYPE',
        });

        // Default to avatar for unknown types
        expect(model.toEntity().type, ProfileHistoryType.avatar);
      });
    });
  });
}
