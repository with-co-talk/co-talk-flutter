import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/datasources/remote/chat_remote_datasource.dart';

void main() {
  group('FileUploadResponse.fromJson - objectId', () {
    test('objectId가 응답에 있으면 파싱한다', () {
      final json = {
        'objectId': 'uploads/42/abc.png',
        'fileUrl': 'http://localhost:9000/cotalk/uploads/42/abc.png',
        'fileName': 'abc.png',
        'contentType': 'image/png',
        'fileSize': 1234,
        'isImage': true,
      };

      final response = FileUploadResponse.fromJson(json);

      expect(response.objectId, 'uploads/42/abc.png');
      expect(response.fileUrl, 'http://localhost:9000/cotalk/uploads/42/abc.png');
    });

    test('objectId가 없으면(구버전 서버) null로 둔다 (하위호환)', () {
      final json = {
        'fileUrl': 'http://localhost:9000/cotalk/uploads/42/abc.png',
        'fileName': 'abc.png',
        'contentType': 'image/png',
        'fileSize': 1234,
        'isImage': true,
      };

      final response = FileUploadResponse.fromJson(json);

      expect(response.objectId, isNull);
      expect(response.fileUrl, isNotNull);
    });
  });

  group('SendFileMessageRequest.toJson - object-id 우선 전송', () {
    test('objectId가 있으면 objectId와 fileUrl을 함께 전송한다(하위호환)', () {
      const request = SendFileMessageRequest(
        chatRoomId: 1,
        objectId: 'uploads/42/abc.png',
        thumbnailObjectId: 'uploads/42/thumb.png',
        fileUrl: 'http://localhost:9000/cotalk/uploads/42/abc.png',
        fileName: 'abc.png',
        fileSize: 1234,
        contentType: 'image/png',
        thumbnailUrl: 'http://localhost:9000/cotalk/uploads/42/thumb.png',
      );

      final json = request.toJson();

      // 신규: object-id 포함
      expect(json['objectId'], 'uploads/42/abc.png');
      expect(json['thumbnailObjectId'], 'uploads/42/thumb.png');
      // 하위호환: fileUrl도 항상 포함
      expect(json['fileUrl'], 'http://localhost:9000/cotalk/uploads/42/abc.png');
      expect(json['contentType'], 'image/png');
    });

    test('objectId가 없으면(구버전 서버 응답) objectId 키를 보내지 않는다', () {
      const request = SendFileMessageRequest(
        chatRoomId: 1,
        fileUrl: 'http://localhost:9000/cotalk/uploads/42/abc.png',
        fileName: 'abc.png',
        fileSize: 1234,
        contentType: 'image/png',
      );

      final json = request.toJson();

      expect(json.containsKey('objectId'), isFalse);
      expect(json.containsKey('thumbnailObjectId'), isFalse);
      expect(json['fileUrl'], 'http://localhost:9000/cotalk/uploads/42/abc.png');
    });
  });
}
