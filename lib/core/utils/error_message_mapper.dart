import 'package:flutter/services.dart';
import '../errors/exceptions.dart';

/// Exception을 사용자 친화적인 메시지로 변환하는 유틸리티
class ErrorMessageMapper {
  /// Exception을 사용자 친화적인 메시지로 변환
  static String toUserFriendlyMessage(dynamic error) {
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }
    
    if (error is ServerException) {
      return _getServerErrorMessage(error);
    }
    
    if (error is NetworkException) {
      return error.message;
    }
    
    if (error is CacheException) {
      return '데이터를 불러오는 중 오류가 발생했습니다';
    }
    
    if (error is ValidationException) {
      return error.message;
    }

    if (error is ConflictException) {
      return error.message;
    }

    if (error is PlatformException) {
      return '기기 저장소 오류가 발생했습니다. 앱을 재시작해주세요.';
    }

    // 알 수 없는 에러의 경우
    return '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }
  
  static String _getAuthErrorMessage(AuthException error) {
    switch (error.type) {
      case AuthErrorType.invalidCredentials:
        return '이메일 또는 비밀번호가 올바르지 않습니다';
      case AuthErrorType.emailNotVerified:
        return '이메일 인증이 완료되지 않았습니다. 이메일을 확인해주세요';
      case AuthErrorType.tokenExpired:
        return '세션이 만료되었습니다. 다시 로그인해주세요';
      case AuthErrorType.tokenInvalid:
        return '인증 정보가 유효하지 않습니다. 다시 로그인해주세요';
      case AuthErrorType.unauthorized:
        return '인증이 필요합니다. 다시 로그인해주세요';
      case AuthErrorType.unknown:
        return error.message.isNotEmpty 
            ? error.message 
            : '인증 중 오류가 발생했습니다';
    }
  }
  
  static String _getServerErrorMessage(ServerException error) {
    // 서버에서 구체적인 에러 메시지를 보냈으면 우선 사용
    if (error.message.isNotEmpty && error.message != 'Unknown error') {
      return error.message;
    }

    final statusCode = error.statusCode;

    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return '잘못된 요청입니다';
        case 401:
          return '인증이 필요합니다';
        case 403:
          return '권한이 없습니다';
        case 404:
          return '요청한 리소스를 찾을 수 없습니다';
        case 500:
        case 502:
        case 503:
          return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
        default:
          return '서버 오류가 발생했습니다';
      }
    }

    return '서버 오류가 발생했습니다';
  }
}
