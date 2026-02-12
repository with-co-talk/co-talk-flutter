import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:co_talk_flutter/core/services/deep_link_service.dart';
import 'package:co_talk_flutter/core/router/app_router.dart';

class MockAppRouter extends Mock implements AppRouter {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('DeepLinkService', () {
    late DeepLinkService deepLinkService;
    late MockAppRouter mockAppRouter;
    late MockGoRouter mockGoRouter;

    setUp(() {
      mockAppRouter = MockAppRouter();
      mockGoRouter = MockGoRouter();
      when(() => mockAppRouter.router).thenReturn(mockGoRouter);
      deepLinkService = DeepLinkService(mockAppRouter);
    });

    tearDown(() {
      deepLinkService.dispose();
    });

    test('should parse cotalk://chat/{roomId} and navigate to chat room', () {
      // Given
      final uri = Uri.parse('cotalk://chat/123');

      // When
      deepLinkService.handleDeepLinkForTest(uri);

      // Then
      verify(() => mockGoRouter.go('/chat/room/123')).called(1);
    });

    test('should parse cotalk://profile/{userId} and navigate to profile', () {
      // Given
      final uri = Uri.parse('cotalk://profile/456');

      // When
      deepLinkService.handleDeepLinkForTest(uri);

      // Then
      verify(() => mockGoRouter.go('/profile/view/456')).called(1);
    });

    test('should ignore non-cotalk scheme links', () {
      // Given
      final uri = Uri.parse('https://example.com/chat/123');

      // When
      deepLinkService.handleDeepLinkForTest(uri);

      // Then
      verifyNever(() => mockGoRouter.go(any()));
    });

    test('should ignore invalid room IDs', () {
      // Given
      final uri = Uri.parse('cotalk://chat/invalid');

      // When
      deepLinkService.handleDeepLinkForTest(uri);

      // Then
      verifyNever(() => mockGoRouter.go(any()));
    });

    test('should store pending deep link', () {
      // Given
      final uri = Uri.parse('cotalk://chat/789');

      // When - store as pending
      deepLinkService.storePendingDeepLink(uri);

      // Then - process pending
      deepLinkService.processPendingDeepLink();
      verify(() => mockGoRouter.go('/chat/room/789')).called(1);
    });
  });
}
