import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/chat/widgets/photo_swipe_viewer.dart';

void main() {
  const testUrls = [
    'https://example.com/1.jpg',
    'https://example.com/2.jpg',
    'https://example.com/3.jpg',
  ];

  Widget createWidgetUnderTest({
    required List<String> imageUrls,
    int initialIndex = 0,
    VoidCallback? Function(int index)? onSaveToGallery,
  }) {
    return MaterialApp(
      home: PhotoSwipeViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
        onSaveToGallery: onSaveToGallery,
      ),
    );
  }

  group('PhotoSwipeViewer', () {
    testWidgets('단일 이미지로 렌더링된다', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(imageUrls: [testUrls[0]]),
      );

      expect(find.byType(PhotoSwipeViewer), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('여러 이미지일 때 페이지 인디케이터(N/N)를 표시한다', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(imageUrls: testUrls),
      );

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('단일 이미지일 때 페이지 인디케이터를 표시하지 않는다', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(imageUrls: [testUrls[0]]),
      );

      expect(find.textContaining(' / '), findsNothing);
    });

    testWidgets('onSaveToGallery가 제공되면 다운로드 버튼을 표시한다', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          imageUrls: testUrls,
          onSaveToGallery: (index) => () {},
        ),
      );

      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('onSaveToGallery가 null이면 다운로드 버튼을 표시하지 않는다',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          imageUrls: testUrls,
          onSaveToGallery: null,
        ),
      );

      expect(find.byIcon(Icons.download_rounded), findsNothing);
    });

    testWidgets('initialIndex가 지정되면 해당 페이지로 시작한다', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(imageUrls: testUrls, initialIndex: 1),
      );

      expect(find.text('2 / 3'), findsOneWidget);
    });
  });
}
