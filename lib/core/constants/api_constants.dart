class ApiConstants {
  ApiConstants._();

  // Base URL - 개발 환경에 맞게 수정
  static const String baseUrl = 'http://localhost:8080';
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  // WebSocket
  static const String wsBaseUrl = 'ws://localhost:8080/ws';

  // Auth Endpoints
  static const String signUp = '/auth/signup';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User Endpoints
  static const String users = '/users';
  static const String userSearch = '/users/search';

  // Friend Endpoints
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';

  // Chat Endpoints
  static const String chatRooms = '/chat/rooms';
  static const String chatMessages = '/chat/messages';
  static const String chatReactions = '/chat/reactions';

  // Block & Report
  static const String blocks = '/blocks';
  static const String reports = '/reports';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
