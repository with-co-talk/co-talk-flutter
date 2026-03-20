import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/data/models/media_gallery_model.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/media_gallery_bloc.dart';
import 'package:co_talk_flutter/presentation/pages/chat/media_gallery_page.dart';

class MockMediaGalleryBloc extends MockBloc<MediaGalleryEvent, MediaGalleryState>
    implements MediaGalleryBloc {}

void main() {
  late MockMediaGalleryBloc mockBloc;
  late StreamController<MediaGalleryState> stateController;

  // Mock url_launcher so file/link taps don't crash
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'canLaunch') return true;
        if (methodCall.method == 'launch') return true;
        return null;
      },
    );
    registerFallbackValue(const MediaGalleryLoadRequested(roomId: 1, type: MediaType.photo));
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    );
  });

  setUp(() {
    mockBloc = MockMediaGalleryBloc();
    stateController = StreamController<MediaGalleryState>.broadcast();

    // Register mock bloc in GetIt so _MediaTab can retrieve it
    if (!GetIt.instance.isRegistered<MediaGalleryBloc>()) {
      GetIt.instance.registerFactory<MediaGalleryBloc>(() => mockBloc);
    } else {
      GetIt.instance.unregister<MediaGalleryBloc>();
      GetIt.instance.registerFactory<MediaGalleryBloc>(() => mockBloc);
    }

    // Stub close() so BlocProvider can dispose properly
    when(() => mockBloc.close()).thenAnswer((_) async {});
    // Stub isClosed
    when(() => mockBloc.isClosed).thenReturn(false);
    // Stub stream with broadcast so multiple BlocProviders can subscribe
    when(() => mockBloc.stream).thenAnswer((_) => stateController.stream);
  });

  tearDown(() async {
    if (GetIt.instance.isRegistered<MediaGalleryBloc>()) {
      GetIt.instance.unregister<MediaGalleryBloc>();
    }
    await stateController.close();
  });

  void stubBlocState(MediaGalleryState state) {
    when(() => mockBloc.state).thenReturn(state);
  }

  Widget buildWidget({int roomId = 1}) {
    return MaterialApp(
      home: MediaGalleryPage(roomId: roomId),
    );
  }

  const loadingState = MediaGalleryState(status: MediaGalleryStatus.loading);
  const emptySuccessState = MediaGalleryState(status: MediaGalleryStatus.success);
  const failureState = MediaGalleryState(
    status: MediaGalleryStatus.failure,
    errorMessage: '미디어를 불러올 수 없습니다',
    roomId: 1,
  );

  final photoItems = [
    MediaGalleryItem(
      messageId: 1,
      type: 'IMAGE',
      fileUrl: 'https://example.com/image1.jpg',
      thumbnailUrl: 'https://example.com/thumb1.jpg',
      contentType: 'image/jpeg',
      fileName: 'image1.jpg',
      fileSize: 1024,
      createdAt: DateTime(2024, 1, 1),
      senderId: 100,
    ),
    MediaGalleryItem(
      messageId: 2,
      type: 'IMAGE',
      fileUrl: 'https://example.com/image2.jpg',
      contentType: 'image/jpeg',
      fileName: 'image2.jpg',
      fileSize: 2048,
      createdAt: DateTime(2024, 1, 2),
      senderId: 101,
    ),
  ];

  final fileItems = [
    MediaGalleryItem(
      messageId: 3,
      type: 'FILE',
      fileUrl: 'https://example.com/document.pdf',
      fileName: 'document.pdf',
      fileSize: 5120,
      contentType: 'application/pdf',
      createdAt: DateTime(2024, 3, 15),
      senderId: 100,
    ),
  ];

  final linkItems = [
    MediaGalleryItem(
      messageId: 4,
      type: 'TEXT',
      linkPreviewUrl: 'https://flutter.dev',
      linkPreviewTitle: 'Flutter',
      linkPreviewDescription: 'Build apps for any screen',
      createdAt: DateTime(2024, 3, 20),
      senderId: 100,
    ),
  ];

  group('MediaGalleryPage', () {
    group('app bar and tabs', () {
      testWidgets('renders app bar with title', (tester) async {
        stubBlocState(loadingState);
        await tester.pumpWidget(buildWidget());

        expect(find.text('미디어 모아보기'), findsOneWidget);
      });

      testWidgets('renders three tabs: 사진, 파일, 링크', (tester) async {
        stubBlocState(loadingState);
        await tester.pumpWidget(buildWidget());

        expect(find.text('사진'), findsOneWidget);
        expect(find.text('파일'), findsOneWidget);
        expect(find.text('링크'), findsOneWidget);
      });

      testWidgets('has a TabBar', (tester) async {
        stubBlocState(loadingState);
        await tester.pumpWidget(buildWidget());

        expect(find.byType(TabBar), findsOneWidget);
      });

      testWidgets('has a TabBarView', (tester) async {
        stubBlocState(loadingState);
        await tester.pumpWidget(buildWidget());

        expect(find.byType(TabBarView), findsOneWidget);
      });
    });

    group('loading state', () {
      testWidgets('shows CircularProgressIndicator while loading with empty items',
          (tester) async {
        stubBlocState(loadingState);
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('error state', () {
      testWidgets('shows error icon on failure', (tester) async {
        stubBlocState(failureState);
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows error message on failure', (tester) async {
        stubBlocState(failureState);
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('미디어를 불러올 수 없습니다'), findsOneWidget);
      });

      testWidgets('shows retry button on failure', (tester) async {
        stubBlocState(failureState);
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('다시 시도'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('tapping retry button dispatches MediaGalleryLoadRequested', (tester) async {
        stubBlocState(failureState);
        await tester.pumpWidget(buildWidget(roomId: 1));
        await tester.pump();

        await tester.tap(find.text('다시 시도'));
        await tester.pump();

        verify(() => mockBloc.add(any(that: isA<MediaGalleryLoadRequested>()))).called(
          greaterThan(0),
        );
      });
    });

    group('empty state', () {
      testWidgets('shows empty photo message when photo tab is empty', (tester) async {
        stubBlocState(emptySuccessState);
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('사진이 없습니다'), findsOneWidget);
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      });

      testWidgets('shows empty file message when file tab is empty', (tester) async {
        stubBlocState(emptySuccessState);
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        // Switch to the 파일 tab
        await tester.tap(find.text('파일'));
        await tester.pumpAndSettle();

        expect(find.text('파일이 없습니다'), findsOneWidget);
        expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      });

      testWidgets('shows empty link message when link tab is empty', (tester) async {
        stubBlocState(emptySuccessState);
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        // Switch to the 링크 tab
        await tester.tap(find.text('링크'));
        await tester.pumpAndSettle();

        expect(find.text('링크가 없습니다'), findsOneWidget);
        expect(find.byIcon(Icons.link_off), findsOneWidget);
      });
    });

    group('photos tab with items', () {
      testWidgets('shows GridView when photos are present', (tester) async {
        stubBlocState(MediaGalleryState(
          status: MediaGalleryStatus.success,
          items: photoItems,
          currentType: MediaType.photo,
        ));

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.byType(GridView), findsOneWidget);
      });
    });

    group('files tab with items', () {
      testWidgets('shows ListView with file items when file tab is selected', (tester) async {
        stubBlocState(MediaGalleryState(
          status: MediaGalleryStatus.success,
          items: fileItems,
          currentType: MediaType.file,
        ));

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        // Switch to the 파일 tab
        await tester.tap(find.text('파일'));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('document.pdf'), findsOneWidget);
      });
    });

    group('links tab with items', () {
      testWidgets('shows ListView with link items when link tab is selected', (tester) async {
        stubBlocState(MediaGalleryState(
          status: MediaGalleryStatus.success,
          items: linkItems,
          currentType: MediaType.link,
        ));

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        // Switch to the 링크 tab
        await tester.tap(find.text('링크'));
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
        expect(find.text('Flutter'), findsOneWidget);
      });
    });

    group('BLoC event dispatching', () {
      testWidgets('dispatches MediaGalleryLoadRequested on photo tab init', (tester) async {
        stubBlocState(loadingState);

        await tester.pumpWidget(buildWidget(roomId: 42));
        await tester.pump();

        verify(
          () => mockBloc.add(
            const MediaGalleryLoadRequested(roomId: 42, type: MediaType.photo),
          ),
        ).called(1);
      });
    });
  });
}
