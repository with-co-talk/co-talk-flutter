import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/dio_client.dart';
import '../../models/link_preview_model.dart';

/// 링크 미리보기 원격 데이터 소스.
/// 서버 API를 통해 URL의 미리보기 정보를 조회한다.
abstract class LinkPreviewRemoteDataSource {
  /// URL에서 미리보기 정보를 조회한다.
  ///
  /// [url] 미리보기 정보를 조회할 URL
  /// 반환: 미리보기 정보 모델
  Future<LinkPreviewModel> getLinkPreview(String url);
}

/// [LinkPreviewRemoteDataSource]의 구현체.
@LazySingleton(as: LinkPreviewRemoteDataSource)
class LinkPreviewRemoteDataSourceImpl implements LinkPreviewRemoteDataSource {
  final DioClient _dioClient;

  LinkPreviewRemoteDataSourceImpl(this._dioClient);

  @override
  Future<LinkPreviewModel> getLinkPreview(String url) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/v1/link-preview',
        queryParameters: {'url': url},
      );

      return LinkPreviewModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('유효하지 않은 URL입니다.');
      }
      throw Exception('링크 미리보기를 불러올 수 없습니다.');
    }
  }
}
