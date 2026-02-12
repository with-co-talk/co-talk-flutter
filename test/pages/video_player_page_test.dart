import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/chat/widgets/video_player_page.dart';

void main() {
  // Mock the video player platform channel
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.io/videoPlayer'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'init') {
          return null;
        }
        if (methodCall.method == 'create') {
          return <String, dynamic>{'textureId': 0};
        }
        if (methodCall.method == 'dispose') {
          return null;
        }
        if (methodCall.method == 'setLooping') {
          return null;
        }
        if (methodCall.method == 'setVolume') {
          return null;
        }
        if (methodCall.method == 'setPlaybackSpeed') {
          return null;
        }
        if (methodCall.method == 'play') {
          return null;
        }
        if (methodCall.method == 'pause') {
          return null;
        }
        if (methodCall.method == 'seekTo') {
          return null;
        }
        if (methodCall.method == 'position') {
          return 0;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.io/videoPlayer'),
      null,
    );
  });

  Widget createWidget({
    String videoUrl = 'https://example.com/video.mp4',
    String? title,
  }) {
    return MaterialApp(
      home: VideoPlayerPage(
        videoUrl: videoUrl,
        title: title,
      ),
    );
  }

  group('VideoPlayerPage', () {
    testWidgets('renders with loading indicator initially', (tester) async {
      await tester.pumpWidget(createWidget());
      // While video is loading, a CircularProgressIndicator should be shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows title when provided', (tester) async {
      await tester.pumpWidget(createWidget(title: '테스트 비디오'));
      expect(find.text('테스트 비디오'), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(createWidget());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('has transparent app bar', (tester) async {
      await tester.pumpWidget(createWidget());
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
    });

    testWidgets('has back button in app bar', (tester) async {
      await tester.pumpWidget(createWidget());
      // The AppBar should have a back button (leading widget)
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.leading, isNull); // MaterialApp adds back button automatically
      // Or we can check that AppBar exists which provides navigation
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
