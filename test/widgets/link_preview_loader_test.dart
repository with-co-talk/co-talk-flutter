import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/domain/entities/link_preview.dart';
import 'package:co_talk_flutter/domain/repositories/link_preview_repository.dart';
import 'package:co_talk_flutter/presentation/widgets/link_preview_card.dart';
import 'package:co_talk_flutter/presentation/widgets/link_preview_loader.dart';

class MockLinkPreviewRepository extends Mock implements LinkPreviewRepository {}

void main() {
  late MockLinkPreviewRepository mockRepo;

  setUp(() {
    mockRepo = MockLinkPreviewRepository();
    // Register the mock in the DI container for test
    if (!GetIt.instance.isRegistered<LinkPreviewRepository>()) {
      GetIt.instance.registerLazySingleton<LinkPreviewRepository>(() => mockRepo);
    } else {
      // Unregister and re-register to use the fresh mock
      GetIt.instance.unregister<LinkPreviewRepository>();
      GetIt.instance.registerLazySingleton<LinkPreviewRepository>(() => mockRepo);
    }
  });

  tearDown(() async {
    if (GetIt.instance.isRegistered<LinkPreviewRepository>()) {
      GetIt.instance.unregister<LinkPreviewRepository>();
    }
  });

  Widget buildWidget({
    String url = 'https://example.com',
    bool isMe = false,
    double maxWidth = 280,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: LinkPreviewLoader(
          url: url,
          isMe: isMe,
          maxWidth: maxWidth,
        ),
      ),
    );
  }

  const validPreview = LinkPreview(
    url: 'https://example.com',
    title: 'Example Title',
    description: 'Example description',
    domain: 'example.com',
  );

  group('LinkPreviewLoader', () {
    group('loading state', () {
      testWidgets('shows nothing while loading (returns SizedBox.shrink)', (tester) async {
        // Return a valid preview so no retry timer is scheduled
        when(() => mockRepo.getLinkPreview(any()))
            .thenAnswer((_) async => validPreview);

        await tester.pumpWidget(buildWidget());

        // Immediately after pumping, before the future resolves, widget shows nothing
        expect(find.byType(LinkPreviewCard), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Complete by settling
        await tester.pumpAndSettle();
      });
    });

    group('success state', () {
      testWidgets('shows LinkPreviewCard when preview is valid and loading succeeds',
          (tester) async {
        when(() => mockRepo.getLinkPreview(any()))
            .thenAnswer((_) async => validPreview);

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.byType(LinkPreviewCard), findsOneWidget);
        expect(find.text('Example Title'), findsOneWidget);
      });

      testWidgets('passes isMe flag to LinkPreviewCard', (tester) async {
        when(() => mockRepo.getLinkPreview(any()))
            .thenAnswer((_) async => validPreview);

        await tester.pumpWidget(buildWidget(isMe: true));
        await tester.pumpAndSettle();

        final card = tester.widget<LinkPreviewCard>(find.byType(LinkPreviewCard));
        expect(card.isMe, isTrue);
      });

      testWidgets('passes maxWidth to LinkPreviewCard', (tester) async {
        when(() => mockRepo.getLinkPreview(any()))
            .thenAnswer((_) async => validPreview);

        await tester.pumpWidget(buildWidget(maxWidth: 320));
        await tester.pumpAndSettle();

        final card = tester.widget<LinkPreviewCard>(find.byType(LinkPreviewCard));
        expect(card.maxWidth, 320.0);
      });

      testWidgets('calls getLinkPreview with the provided url', (tester) async {
        when(() => mockRepo.getLinkPreview(any()))
            .thenAnswer((_) async => validPreview);

        await tester.pumpWidget(buildWidget(url: 'https://flutter.dev'));
        await tester.pumpAndSettle();

        verify(() => mockRepo.getLinkPreview('https://flutter.dev')).called(greaterThan(0));
      });
    });

    group('invalid preview state', () {
      testWidgets('shows nothing when preview has no title and no image (invalid)',
          (tester) async {
        // Return empty preview on all attempts so the retry loop exhausts all attempts
        when(() => mockRepo.getLinkPreview(any()))
            .thenAnswer((_) async => LinkPreview.empty('https://example.com'));

        await tester.pumpWidget(buildWidget());
        // Allow all retry delays (2 retries × 3s = 6s) to drain
        await tester.pumpAndSettle(const Duration(seconds: 15));

        // Empty/invalid preview → widget is not displayed
        expect(find.byType(LinkPreviewCard), findsNothing);
      });
    });

    group('error state', () {
      testWidgets('shows nothing when all retries fail with an exception', (tester) async {
        // All retry attempts throw
        when(() => mockRepo.getLinkPreview(any()))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildWidget());
        // Allow all retry attempts and delays to resolve
        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(find.byType(LinkPreviewCard), findsNothing);
      });

      testWidgets('shows nothing when loading fails (no UI error widget shown)',
          (tester) async {
        when(() => mockRepo.getLinkPreview(any()))
            .thenThrow(Exception('Failure'));

        await tester.pumpWidget(buildWidget());
        // Allow all retry delays to drain
        await tester.pumpAndSettle(const Duration(seconds: 15));

        expect(find.byType(LinkPreviewCard), findsNothing);
        // No error icon or error text shown to user
        expect(find.byIcon(Icons.error), findsNothing);
      });
    });

    group('retry behavior', () {
      testWidgets('succeeds on second attempt after first fails', (tester) async {
        var callCount = 0;
        when(() => mockRepo.getLinkPreview(any())).thenAnswer((_) async {
          callCount++;
          if (callCount < 2) {
            throw Exception('First attempt fails');
          }
          return validPreview;
        });

        await tester.pumpWidget(buildWidget());
        // Wait for retries (with delay of 3 seconds each)
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.byType(LinkPreviewCard), findsOneWidget);
        expect(callCount, greaterThanOrEqualTo(2));
      });
    });
  });
}
