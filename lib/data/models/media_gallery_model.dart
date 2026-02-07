import 'package:equatable/equatable.dart';

/// Media gallery item model for photos, files, and links.
class MediaGalleryItem extends Equatable {
  final int messageId;
  final String type; // IMAGE, FILE, TEXT
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? contentType;
  final String? thumbnailUrl;
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImageUrl;
  final DateTime createdAt;
  final int senderId;
  final String? senderNickname;

  const MediaGalleryItem({
    required this.messageId,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.contentType,
    this.thumbnailUrl,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewImageUrl,
    required this.createdAt,
    required this.senderId,
    this.senderNickname,
  });

  factory MediaGalleryItem.fromJson(Map<String, dynamic> json) {
    return MediaGalleryItem(
      messageId: json['messageId'] as int,
      type: json['type'] as String,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      contentType: json['contentType'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      linkPreviewUrl: json['linkPreviewUrl'] as String?,
      linkPreviewTitle: json['linkPreviewTitle'] as String?,
      linkPreviewDescription: json['linkPreviewDescription'] as String?,
      linkPreviewImageUrl: json['linkPreviewImageUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      senderId: json['senderId'] as int,
      senderNickname: json['senderNickname'] as String?,
    );
  }

  @override
  List<Object?> get props => [messageId, type, fileUrl, createdAt];
}

/// Media gallery response model with pagination.
class MediaGalleryResponse {
  final List<MediaGalleryItem> items;
  final int? nextCursor;
  final bool hasMore;

  const MediaGalleryResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory MediaGalleryResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>;
    return MediaGalleryResponse(
      items: itemsJson
          .map((item) => MediaGalleryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as int?,
      hasMore: json['hasMore'] as bool,
    );
  }
}

/// Media type for gallery queries.
enum MediaType {
  photo,
  file,
  link;

  String get apiValue {
    switch (this) {
      case MediaType.photo:
        return 'PHOTO';
      case MediaType.file:
        return 'FILE';
      case MediaType.link:
        return 'LINK';
    }
  }
}
