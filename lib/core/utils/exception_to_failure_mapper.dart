import '../errors/exceptions.dart';
import '../errors/failures.dart';

/// Exception을 Failure로 변환하는 유틸리티
class ExceptionToFailureMapper {
  /// Exception을 Failure로 변환
  static Failure toFailure(dynamic exception) {
    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
      );
    }
    
    if (exception is NetworkException) {
      return NetworkFailure(message: exception.message);
    }
    
    if (exception is CacheException) {
      return CacheFailure(message: exception.message);
    }
    
    if (exception is AuthException) {
      return AuthFailure(message: exception.message);
    }
    
    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        fieldErrors: exception.fieldErrors,
      );
    }
    
    // 알 수 없는 Exception의 경우
    return ServerFailure(
      message: exception.toString(),
    );
  }
}
