class ApiConstants {
  ApiConstants._();

  // 환경 설정 (빌드 시 --dart-define으로 설정)
  static const String _environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  // Base URL - 환경별 자동 설정
  static String get baseUrl {
    switch (_environment) {
      case 'prod':
        // 프로덕션 URL (Synology NAS)
        const prodUrl =
            String.fromEnvironment('API_URL', defaultValue: 'https://co-talk.sgyj-dev.synology.me');
        return prodUrl;
      case 'staging':
        return 'https://staging-api.cotalk.com';
      case 'dev':
      default:
        return 'http://localhost:8080';
    }
  }

  static const String apiVersion = '/api/v1';
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // WebSocket
  static String get wsBaseUrl {
    final uri = Uri.parse(baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${uri.host}:${uri.port}/ws';
  }

  // Auth Endpoints
  static const String signUp = '/auth/signup';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User Endpoints
  static const String users = '/users';
  static const String userSearch = '/users/search';
  static const String fcmToken = '/devices/token';
  static String userProfile(int userId) => '/users/$userId/profile';

  // Profile History Endpoints
  static String profileHistory(int userId) => '/users/$userId/profile/history';
  static String profileHistoryItem(int userId, int historyId) => '/users/$userId/profile/history/$historyId';
  static String profileHistoryCurrent(int userId, int historyId) => '/users/$userId/profile/history/$historyId/current';

  // File Endpoints
  static const String fileUpload = '/files/upload';

  // Friend Endpoints
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';
  static String friendHide(int id) => '/friends/$id/hide';
  static const String hiddenFriends = '/friends/hidden';

  // Chat Endpoints
  static const String chatRooms = '/chat/rooms';
  static String chatRoom(int roomId) => '/chat/rooms/$roomId';
  static const String chatMessages = '/chat/messages';
  static const String chatReactions = '/chat/reactions';

  // Block & Report
  static const String blocks = '/blocks';
  static String blockUser(int id) => '/blocks/$id';
  static const String reports = '/reports';

  // Settings Endpoints
  static const String notificationSettings = '/notifications/settings';
  static String accountDeletion(int userId) => '/account/$userId';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
