class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Co-Talk';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';

  // Pagination
  static const int defaultPageSize = 20;
  static const int messagePageSize = 50;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 100;
  static const int minNicknameLength = 2;
  static const int maxNicknameLength = 20;

  // Chat
  static const int maxMessageLength = 5000;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Desktop Window
  static const double minWindowWidth = 400;
  static const double minWindowHeight = 600;
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
}
