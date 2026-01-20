class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final AuthErrorType type;

  const AuthException({
    required this.message,
    required this.type,
  });

  @override
  String toString() => 'AuthException: $message (type: $type)';
}

enum AuthErrorType {
  invalidCredentials,
  tokenExpired,
  tokenInvalid,
  unauthorized,
  unknown,
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}
