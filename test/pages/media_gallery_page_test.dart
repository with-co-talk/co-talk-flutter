import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:co_talk_flutter/data/models/media_gallery_model.dart';
import 'package:co_talk_flutter/di/injection.dart';
import 'package:co_talk_flutter/presentation/blocs/chat/media_gallery_bloc.dart';
import 'package:co_talk_flutter/presentation/pages/chat/media_gallery_page.dart';

class MockMediaGalleryBloc
    extends MockBloc<MediaGalleryEvent, MediaGalleryState>
    implements MediaGalleryBloc {}

void main() {
  late MockMediaGalleryBloc mockBloc;

  setUp(() {
    mockBloc = MockMediaGalleryBloc();
    if (getIt.isRegistered<MediaGalleryBloc>()) {
      getIt.unregister<MediaGalleryBloc>();
    }
    getIt.registerFactory<MediaGalleryBloc>(() => mockBloc);
  });

  tearDown(() {
    if (getIt.isRegistered<MediaGalleryBloc>()) {
      getIt.unregister<MediaGalleryBloc>();
    }
  });

  // thumbnailUrl 이 null 인 사진 항목 — 풀해상도 원본(fileUrl)을 작은 그리드
  // 셀에 디코딩하므로 memCacheWidth 다운샘플링이 반드시 필요한 OOM 케이스.
  final photoNoThumb = MediaGalleryItem(
    messageId: 1,
    type: 'IMAGE',
    fileUrl: 'https://example.com/full_resolution.jpg',
    thumbnailUrl: null,
    contentType: 'image/jpeg',
    createdAt: DateTime(2024, 1, 1),
    senderId: 100,
  );

  Widget createWidget() {
    return const MaterialApp(
      home: MediaGalleryPage(roomId: 1),
    );
  }

  testWidgets(
    'photo grid sets memCacheWidth to downsample full-resolution images (P2 OOM)',
    (tester) async {
      whenListen(
        mockBloc,
        const Stream<MediaGalleryState>.empty(),
        initialState: MediaGalleryState(
          status: MediaGalleryStatus.success,
          items: [photoNoThumb],
          hasMore: false,
          currentPage: 0,
          currentType: MediaType.photo,
          roomId: 1,
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // The first tab (photo) renders the grid. Every CachedNetworkImage in
      // the grid must carry a non-null, bounded memCacheWidth so that the
      // raw origin is downsampled instead of decoded at full resolution.
      final gridImages = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .where((img) => img.imageUrl == photoNoThumb.fileUrl)
          .toList();

      expect(gridImages, isNotEmpty);
      for (final img in gridImages) {
        expect(img.memCacheWidth, isNotNull,
            reason: 'grid cell image must specify memCacheWidth');
        expect(img.memCacheWidth! > 0, isTrue);
        // Sanity: cache width should be a small cell, well under a 4K origin.
        expect(img.memCacheWidth! < 4000, isTrue);
      }
    },
  );
}
