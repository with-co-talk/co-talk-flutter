import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/datasources/remote/profile_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/profile_history_model.dart';
import 'package:co_talk_flutter/data/repositories/profile_repository_impl.dart';
import 'package:co_talk_flutter/domain/entities/profile_history.dart';

class MockProfileRemoteDataSource extends Mock implements ProfileRemoteDataSource {}

void main() {
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late ProfileRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(mockRemoteDataSource);
  });

  final testModel = ProfileHistoryModel(
    id: 1,
    userId: 100,
    type: 'AVATAR',
    url: 'https://example.com/avatar.jpg',
    isPrivate: false,
    isCurrent: true,
    createdAt: DateTime(2024, 1, 1),
  );

  group('ProfileRepositoryImpl', () {
    group('getProfileHistory', () {
      test('returns list of entities', () async {
        when(() => mockRemoteDataSource.getProfileHistory(
              any(),
              type: any(named: 'type'),
            )).thenAnswer((_) async => [testModel]);

        final result = await repository.getProfileHistory(100);

        expect(result, isA<List<ProfileHistory>>());
        expect(result.length, 1);
        expect(result[0].id, 1);
        expect(result[0].type, ProfileHistoryType.avatar);
        verify(() => mockRemoteDataSource.getProfileHistory(100, type: null)).called(1);
      });

      test('converts type enum to string when filtering', () async {
        when(() => mockRemoteDataSource.getProfileHistory(
              any(),
              type: any(named: 'type'),
            )).thenAnswer((_) async => [testModel]);

        await repository.getProfileHistory(100, type: ProfileHistoryType.avatar);

        verify(() => mockRemoteDataSource.getProfileHistory(
              100,
              type: 'AVATAR',
            )).called(1);
      });

      test('handles empty list', () async {
        when(() => mockRemoteDataSource.getProfileHistory(
              any(),
              type: any(named: 'type'),
            )).thenAnswer((_) async => []);

        final result = await repository.getProfileHistory(100);

        expect(result, isEmpty);
      });

      test('converts multiple models to entities', () async {
        final models = [
          testModel,
          ProfileHistoryModel(
            id: 2,
            userId: 100,
            type: 'STATUS_MESSAGE',
            content: 'Hello',
            isPrivate: false,
            isCurrent: true,
            createdAt: DateTime(2024, 1, 2),
          ),
        ];

        when(() => mockRemoteDataSource.getProfileHistory(
              any(),
              type: any(named: 'type'),
            )).thenAnswer((_) async => models);

        final result = await repository.getProfileHistory(100);

        expect(result.length, 2);
        expect(result[0].type, ProfileHistoryType.avatar);
        expect(result[1].type, ProfileHistoryType.statusMessage);
      });

      test('throws exception when datasource fails', () async {
        when(() => mockRemoteDataSource.getProfileHistory(
              any(),
              type: any(named: 'type'),
            )).thenThrow(Exception('Network error'));

        expect(
          () => repository.getProfileHistory(100),
          throwsException,
        );
      });
    });

    group('createProfileHistory', () {
      test('returns created entity', () async {
        when(() => mockRemoteDataSource.createProfileHistory(
              userId: any(named: 'userId'),
              type: any(named: 'type'),
              url: any(named: 'url'),
              content: any(named: 'content'),
              isPrivate: any(named: 'isPrivate'),
              setCurrent: any(named: 'setCurrent'),
            )).thenAnswer((_) async => testModel);

        final result = await repository.createProfileHistory(
          userId: 100,
          type: ProfileHistoryType.avatar,
          url: 'https://example.com/avatar.jpg',
        );

        expect(result, isA<ProfileHistory>());
        expect(result.id, 1);
        expect(result.type, ProfileHistoryType.avatar);
        expect(result.url, 'https://example.com/avatar.jpg');
      });

      test('converts type enum to string', () async {
        when(() => mockRemoteDataSource.createProfileHistory(
              userId: any(named: 'userId'),
              type: any(named: 'type'),
              url: any(named: 'url'),
              content: any(named: 'content'),
              isPrivate: any(named: 'isPrivate'),
              setCurrent: any(named: 'setCurrent'),
            )).thenAnswer((_) async => testModel);

        await repository.createProfileHistory(
          userId: 100,
          type: ProfileHistoryType.avatar,
          url: 'https://example.com/avatar.jpg',
        );

        verify(() => mockRemoteDataSource.createProfileHistory(
              userId: 100,
              type: 'AVATAR',
              url: 'https://example.com/avatar.jpg',
              content: null,
              isPrivate: false,
              setCurrent: true,
            )).called(1);
      });

      test('converts background type correctly', () async {
        final backgroundModel = ProfileHistoryModel(
          id: 2,
          userId: 100,
          type: 'BACKGROUND',
          url: 'https://example.com/bg.jpg',
          isPrivate: false,
          isCurrent: false,
          createdAt: DateTime(2024, 1, 1),
        );

        when(() => mockRemoteDataSource.createProfileHistory(
              userId: any(named: 'userId'),
              type: any(named: 'type'),
              url: any(named: 'url'),
              content: any(named: 'content'),
              isPrivate: any(named: 'isPrivate'),
              setCurrent: any(named: 'setCurrent'),
            )).thenAnswer((_) async => backgroundModel);

        await repository.createProfileHistory(
          userId: 100,
          type: ProfileHistoryType.background,
          url: 'https://example.com/bg.jpg',
        );

        verify(() => mockRemoteDataSource.createProfileHistory(
              userId: 100,
              type: 'BACKGROUND',
              url: 'https://example.com/bg.jpg',
              content: null,
              isPrivate: false,
              setCurrent: true,
            )).called(1);
      });

      test('passes all parameters correctly', () async {
        when(() => mockRemoteDataSource.createProfileHistory(
              userId: any(named: 'userId'),
              type: any(named: 'type'),
              url: any(named: 'url'),
              content: any(named: 'content'),
              isPrivate: any(named: 'isPrivate'),
              setCurrent: any(named: 'setCurrent'),
            )).thenAnswer((_) async => testModel);

        await repository.createProfileHistory(
          userId: 100,
          type: ProfileHistoryType.statusMessage,
          content: 'Hello world',
          isPrivate: true,
          setCurrent: false,
        );

        verify(() => mockRemoteDataSource.createProfileHistory(
              userId: 100,
              type: 'STATUS_MESSAGE',
              url: null,
              content: 'Hello world',
              isPrivate: true,
              setCurrent: false,
            )).called(1);
      });

      test('throws exception when datasource fails', () async {
        when(() => mockRemoteDataSource.createProfileHistory(
              userId: any(named: 'userId'),
              type: any(named: 'type'),
              url: any(named: 'url'),
              content: any(named: 'content'),
              isPrivate: any(named: 'isPrivate'),
              setCurrent: any(named: 'setCurrent'),
            )).thenThrow(Exception('Creation failed'));

        expect(
          () => repository.createProfileHistory(
            userId: 100,
            type: ProfileHistoryType.avatar,
          ),
          throwsException,
        );
      });
    });

    group('updateProfileHistory', () {
      test('completes successfully', () async {
        when(() => mockRemoteDataSource.updateProfileHistory(
              any(),
              any(),
              isPrivate: any(named: 'isPrivate'),
            )).thenAnswer((_) async {});

        await expectLater(
          repository.updateProfileHistory(100, 1, isPrivate: true),
          completes,
        );

        verify(() => mockRemoteDataSource.updateProfileHistory(
              100,
              1,
              isPrivate: true,
            )).called(1);
      });

      test('passes correct parameters', () async {
        when(() => mockRemoteDataSource.updateProfileHistory(
              any(),
              any(),
              isPrivate: any(named: 'isPrivate'),
            )).thenAnswer((_) async {});

        await repository.updateProfileHistory(100, 5, isPrivate: false);

        verify(() => mockRemoteDataSource.updateProfileHistory(
              100,
              5,
              isPrivate: false,
            )).called(1);
      });

      test('throws exception when datasource fails', () async {
        when(() => mockRemoteDataSource.updateProfileHistory(
              any(),
              any(),
              isPrivate: any(named: 'isPrivate'),
            )).thenThrow(Exception('Update failed'));

        expect(
          () => repository.updateProfileHistory(100, 1, isPrivate: true),
          throwsException,
        );
      });
    });

    group('deleteProfileHistory', () {
      test('completes successfully', () async {
        when(() => mockRemoteDataSource.deleteProfileHistory(any(), any()))
            .thenAnswer((_) async {});

        await expectLater(
          repository.deleteProfileHistory(100, 1),
          completes,
        );

        verify(() => mockRemoteDataSource.deleteProfileHistory(100, 1)).called(1);
      });

      test('passes correct parameters', () async {
        when(() => mockRemoteDataSource.deleteProfileHistory(any(), any()))
            .thenAnswer((_) async {});

        await repository.deleteProfileHistory(100, 5);

        verify(() => mockRemoteDataSource.deleteProfileHistory(100, 5)).called(1);
      });

      test('throws exception when datasource fails', () async {
        when(() => mockRemoteDataSource.deleteProfileHistory(any(), any()))
            .thenThrow(Exception('Delete failed'));

        expect(
          () => repository.deleteProfileHistory(100, 1),
          throwsException,
        );
      });
    });

    group('setCurrentProfile', () {
      test('completes successfully', () async {
        when(() => mockRemoteDataSource.setCurrentProfile(any(), any()))
            .thenAnswer((_) async {});

        await expectLater(
          repository.setCurrentProfile(100, 1),
          completes,
        );

        verify(() => mockRemoteDataSource.setCurrentProfile(100, 1)).called(1);
      });

      test('passes correct parameters', () async {
        when(() => mockRemoteDataSource.setCurrentProfile(any(), any()))
            .thenAnswer((_) async {});

        await repository.setCurrentProfile(100, 5);

        verify(() => mockRemoteDataSource.setCurrentProfile(100, 5)).called(1);
      });

      test('throws exception when datasource fails', () async {
        when(() => mockRemoteDataSource.setCurrentProfile(any(), any()))
            .thenThrow(Exception('Set current failed'));

        expect(
          () => repository.setCurrentProfile(100, 1),
          throwsException,
        );
      });
    });
  });
}
