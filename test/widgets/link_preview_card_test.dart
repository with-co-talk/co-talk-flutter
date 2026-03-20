import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/link_preview.dart';
import 'package:co_talk_flutter/presentation/widgets/link_preview_card.dart';

void main() {
  // Mock url_launcher platform channel so taps on the card don't crash
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'canLaunch') {
          return true;
        }
        if (methodCall.method == 'launch') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    );
  });

  Widget buildWidget(LinkPreview preview, {bool isMe = false, double maxWidth = 280}) {
    return MaterialApp(
      home: Scaffold(
        body: LinkPreviewCard(
          preview: preview,
          isMe: isMe,
          maxWidth: maxWidth,
        ),
      ),
    );
  }

  group('LinkPreviewCard', () {
    group('validity check', () {
      testWidgets('shows SizedBox.shrink when preview has no title and no image', (tester) async {
        const preview = LinkPreview(url: 'https://example.com');

        await tester.pumpWidget(buildWidget(preview));

        // The card container should not be rendered
        expect(find.byType(GestureDetector), findsNothing);
        expect(find.byType(Container), findsNothing);
      });

      testWidgets('renders card when preview has a title', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Example Title',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.byType(GestureDetector), findsOneWidget);
        expect(find.text('Example Title'), findsOneWidget);
      });

      testWidgets('renders card when preview has an image and no title', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          imageUrl: 'https://example.com/image.jpg',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.byType(GestureDetector), findsOneWidget);
      });
    });

    group('title and description display', () {
      testWidgets('displays title text', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Test Page Title',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.text('Test Page Title'), findsOneWidget);
      });

      testWidgets('displays description text', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title',
          description: 'This is a test description.',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.text('This is a test description.'), findsOneWidget);
      });

      testWidgets('hides description when not provided', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title Only',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.text('Title Only'), findsOneWidget);
        // No description text should appear
        expect(find.text('description'), findsNothing);
      });

      testWidgets('displays siteName in domain row', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Some Title',
          siteName: 'Example Site',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.text('Example Site'), findsOneWidget);
      });

      testWidgets('falls back to domain when siteName is null', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Some Title',
          domain: 'example.com',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.text('example.com'), findsOneWidget);
      });
    });

    group('image rendering', () {
      testWidgets('shows image widget when imageUrl is provided', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title',
          imageUrl: 'https://example.com/thumbnail.jpg',
        );

        await tester.pumpWidget(buildWidget(preview));

        // Image.network should be present
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('does not show image widget when imageUrl is null', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.byType(Image), findsNothing);
      });
    });

    group('maxWidth constraint', () {
      testWidgets('applies default maxWidth of 280', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title',
        );

        await tester.pumpWidget(buildWidget(preview));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ).first,
        );
        expect(container.constraints?.maxWidth, 280.0);
      });

      testWidgets('applies custom maxWidth', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title',
        );

        await tester.pumpWidget(buildWidget(preview, maxWidth: 200));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(GestureDetector),
            matching: find.byType(Container),
          ).first,
        );
        expect(container.constraints?.maxWidth, 200.0);
      });
    });

    group('styling for isMe', () {
      testWidgets('renders without error when isMe is true', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'My Link',
        );

        await tester.pumpWidget(buildWidget(preview, isMe: true));

        expect(find.text('My Link'), findsOneWidget);
      });

      testWidgets('renders without error when isMe is false', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Their Link',
        );

        await tester.pumpWidget(buildWidget(preview, isMe: false));

        expect(find.text('Their Link'), findsOneWidget);
      });
    });

    group('favicon', () {
      testWidgets('shows language icon when favicon is null', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.byIcon(Icons.language), findsOneWidget);
      });

      testWidgets('shows favicon image when favicon url is provided', (tester) async {
        const preview = LinkPreview(
          url: 'https://example.com',
          title: 'Title',
          favicon: 'https://example.com/favicon.ico',
        );

        await tester.pumpWidget(buildWidget(preview));

        // ClipRRect wraps the favicon Image.network
        expect(find.byType(ClipRRect), findsOneWidget);
      });
    });

    group('full preview', () {
      testWidgets('renders complete preview with all fields', (tester) async {
        // Use a larger screen to ensure everything fits
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const preview = LinkPreview(
          url: 'https://example.com/article',
          title: 'Article Title',
          description: 'Article description text',
          domain: 'example.com',
          siteName: 'Example',
          favicon: 'https://example.com/favicon.ico',
          imageUrl: 'https://example.com/image.jpg',
        );

        await tester.pumpWidget(buildWidget(preview));

        expect(find.text('Article Title'), findsOneWidget);
        expect(find.text('Article description text'), findsOneWidget);
        expect(find.text('Example'), findsOneWidget);
        expect(find.byType(Image), findsAtLeastNWidgets(1));
      });
    });
  });
}
