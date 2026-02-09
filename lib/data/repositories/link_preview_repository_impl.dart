import 'package:injectable/injectable.dart';

import '../../domain/entities/link_preview.dart';
import '../../domain/repositories/link_preview_repository.dart';
import '../datasources/remote/link_preview_remote_datasource.dart';

/// [LinkPreviewRepository]의 구현체.
/// 서버 API를 통해 링크 미리보기 정보를 조회하고 캐싱한다.
@LazySingleton(as: LinkPreviewRepository)
class LinkPreviewRepositoryImpl implements LinkPreviewRepository {
  final LinkPreviewRemoteDataSource _remoteDataSource;

  /// 메모리 캐시 (URL -> LinkPreview)
  final Map<String, LinkPreview> _cache = {};

  /// 캐시 만료 시간 (5분)
  static const _cacheExpiration = Duration(minutes: 5);

  /// 캐시 타임스탬프
  final Map<String, DateTime> _cacheTimestamps = {};

  LinkPreviewRepositoryImpl(this._remoteDataSource);

  @override
  Future<LinkPreview> getLinkPreview(String url) async {
    // 캐시 확인
    if (_cache.containsKey(url)) {
      final timestamp = _cacheTimestamps[url];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiration) {
        return _cache[url]!;
      }
    }

    try {
      final model = await _remoteDataSource.getLinkPreview(url);
      final preview = model.toEntity();

      // 유효한 결과만 캐시 (제목이나 이미지가 있는 경우)
      if (preview.isValid) {
        _cache[url] = preview;
        _cacheTimestamps[url] = DateTime.now();
      }

      return preview;
    } catch (e) {
      // 오류 발생 시 빈 미리보기 반환 (캐시하지 않음 → 재시도 가능)
      return LinkPreview.empty(url);
    }
  }
}
