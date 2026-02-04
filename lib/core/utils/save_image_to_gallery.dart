import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';

import '../../di/injection.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// URL에서 이미지를 다운로드하여 기기 갤러리(사진 앱)에 저장합니다.
///
/// [imageUrl]은 절대 URL 또는 서버 기준 상대 경로(예: /api/v1/files/xxx)일 수 있습니다.
/// 웹 플랫폼에서는 지원하지 않으며 [UnsupportedError]를 던집니다.
/// 갤러리 접근 권한이 없으면 [GalException]을 던질 수 있습니다.
Future<void> saveImageFromUrlToGallery(String imageUrl) async {
  final resolvedUrl = imageUrl.startsWith('http') ? imageUrl : '${ApiConstants.baseUrl}$imageUrl';
  final dio = getIt<DioClient>().dio;
  final response = await dio.get<List<int>>(
    resolvedUrl,
    options: Options(responseType: ResponseType.bytes),
  );
  final bytes = response.data;
  if (bytes == null || bytes.isEmpty) {
    throw Exception('이미지 데이터를 받지 못했습니다');
  }
  final hasAccess = await Gal.hasAccess();
  if (!hasAccess) {
    final granted = await Gal.requestAccess();
    if (!granted) {
      throw Exception('사진 라이브러리 접근 권한이 없습니다');
    }
  }
  await Gal.putImageBytes(Uint8List.fromList(bytes));
}
