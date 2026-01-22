import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';

/// 모든 Remote DataSource의 공통 기능을 제공하는 베이스 클래스
abstract class BaseRemoteDataSource {
  /// Dio 에러를 앱 내부 예외로 변환하는 공통 핸들러
  ///
  /// HTTP 상태 코드에 따라 적절한 예외를 반환:
  /// - 400: ValidationException (잘못된 요청)
  /// - 401: AuthException (인증 실패)
  /// - 403: AuthException (권한 없음)
  /// - 404: ServerException (리소스 없음)
  /// - 422: ValidationException (검증 실패)
  /// - 500+: ServerException (서버 에러)
  ///
  /// 네트워크 에러의 경우 NetworkException 반환
  Exception handleDioError(DioException e) {
    // HTTP 응답이 있는 경우 (서버 에러)
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      // 백엔드 ErrorResponse 형식 우선 확인: { message: "...", code: "...", timestamp: "..." }
      // 또는 { error: "..." } 형식
      final message = _extractErrorMessage(data);
      final code = _extractErrorCode(data);

      return _mapStatusCodeToException(statusCode, message, code: code);
    }

    // 네트워크 에러 (응답 없음)
    return _mapDioExceptionTypeToException(e.type);
  }

  /// HTTP 상태 코드를 적절한 예외로 매핑
  Exception _mapStatusCodeToException(int? statusCode, String message, {String? code}) {
    switch (statusCode) {
      case 400:
        return ValidationException(message: message);

      case 401:
        return AuthException(
          message: message,
          type: _mapCodeToAuthErrorType(code),
        );

      case 403:
        return AuthException(
          message: message,
          type: AuthErrorType.unauthorized,
        );

      case 404:
        return ServerException(
          message: message,
          statusCode: statusCode,
        );

      case 409:
        return ConflictException(
          message: message,
          code: code,
        );

      case 422:
        return ValidationException(message: message);

      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
    }
  }

  /// 백엔드 에러 코드를 AuthErrorType으로 매핑
  AuthErrorType _mapCodeToAuthErrorType(String? code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return AuthErrorType.invalidCredentials;
      case 'TOKEN_EXPIRED':
        return AuthErrorType.tokenExpired;
      case 'TOKEN_INVALID':
        return AuthErrorType.tokenInvalid;
      default:
        return AuthErrorType.unauthorized;
    }
  }

  /// DioExceptionType을 적절한 예외로 매핑
  Exception _mapDioExceptionTypeToException(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkException(message: '서버 연결 시간이 초과되었습니다');

      case DioExceptionType.sendTimeout:
        return const NetworkException(message: '요청 전송 시간이 초과되었습니다');

      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: '응답 수신 시간이 초과되었습니다');

      case DioExceptionType.connectionError:
        return const NetworkException(message: '네트워크 연결에 실패했습니다');

      case DioExceptionType.cancel:
        return const NetworkException(message: '요청이 취소되었습니다');

      default:
        return const NetworkException(message: '네트워크 오류가 발생했습니다');
    }
  }

  /// 에러 응답에서 메시지 추출
  ///
  /// 우선순위:
  /// 1. data['message']
  /// 2. data['error']
  /// 3. 'Unknown error'
  String _extractErrorMessage(dynamic data) {
    if (data == null) {
      return 'Unknown error';
    }

    if (data is Map) {
      // 백엔드 표준 형식: { message: "..." }
      if (data['message'] != null) {
        return data['message'].toString();
      }

      // 대체 형식: { error: "..." }
      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    return 'Unknown error';
  }

  /// 에러 응답에서 에러 코드 추출
  ///
  /// 백엔드 ErrorResponse 형식: { message: "...", code: "INVALID_FRIEND_REQUEST", timestamp: "..." }
  String? _extractErrorCode(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map && data['code'] != null) {
      return data['code'].toString();
    }

    return null;
  }

  /// 응답 데이터가 List인지, Map with key인지 확인하고 List 반환
  ///
  /// 서버가 다양한 형식으로 응답할 수 있는 경우 사용:
  /// - [1, 2, 3] (직접 List)
  /// - { "items": [1, 2, 3] } (Map with key)
  /// - null
  ///
  /// [fallbackKeys] 추가 키들을 지정하면 [key]가 없을 때 순서대로 시도
  List<dynamic> extractListFromResponse(
    dynamic responseData,
    String key, {
    List<String>? fallbackKeys,
  }) {
    if (responseData == null) {
      return [];
    }

    // 직접 List인 경우
    if (responseData is List) {
      return responseData;
    }

    // Map인 경우 key 검색
    if (responseData is Map) {
      // 주요 키로 먼저 시도
      if (responseData[key] != null) {
        final data = responseData[key];
        if (data is List) {
          return data;
        }
      }

      // fallback 키들 순서대로 시도
      if (fallbackKeys != null) {
        for (final fallbackKey in fallbackKeys) {
          if (responseData[fallbackKey] != null) {
            final data = responseData[fallbackKey];
            if (data is List) {
              return data;
            }
          }
        }
      }
    }

    return [];
  }
}
