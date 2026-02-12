import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../models/report_model.dart';
import '../base_remote_datasource.dart';

abstract class ReportRemoteDataSource {
  Future<void> reportUser({
    required int reportedUserId,
    required String reason,
    String? description,
  });

  Future<void> reportMessage({
    required int reportedMessageId,
    required String reason,
    String? description,
  });

  Future<List<ReportModel>> getMyReports();
}

@LazySingleton(as: ReportRemoteDataSource)
class ReportRemoteDataSourceImpl extends BaseRemoteDataSource
    implements ReportRemoteDataSource {
  final DioClient _dioClient;

  ReportRemoteDataSourceImpl(this._dioClient);

  @override
  Future<void> reportUser({
    required int reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _dioClient.post(
        '${ApiConstants.reports}/users',
        data: {
          'reportedUserId': reportedUserId,
          'reason': reason,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<void> reportMessage({
    required int reportedMessageId,
    required String reason,
    String? description,
  }) async {
    try {
      await _dioClient.post(
        '${ApiConstants.reports}/messages',
        data: {
          'reportedMessageId': reportedMessageId,
          'reason': reason,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  @override
  Future<List<ReportModel>> getMyReports() async {
    try {
      final response = await _dioClient.get('${ApiConstants.reports}/my');
      final data = extractListFromResponse(response.data, 'reports');
      return data.map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
