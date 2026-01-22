import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/constants/api_constants.dart';

void main() {
  group('ApiConstants', () {
    group('Base URL configuration', () {
      test('apiBaseUrl contains apiVersion', () {
        expect(ApiConstants.apiBaseUrl, contains(ApiConstants.apiVersion));
      });

      test('apiVersion is /api/v1', () {
        expect(ApiConstants.apiVersion, equals('/api/v1'));
      });

      test('baseUrl returns a valid URL', () {
        expect(ApiConstants.baseUrl, isNotEmpty);
        expect(
          Uri.tryParse(ApiConstants.baseUrl),
          isNotNull,
        );
      });

      test('apiBaseUrl is baseUrl + apiVersion', () {
        expect(
          ApiConstants.apiBaseUrl,
          equals('${ApiConstants.baseUrl}${ApiConstants.apiVersion}'),
        );
      });
    });

    group('WebSocket URL', () {
      test('wsBaseUrl starts with ws or wss', () {
        expect(
          ApiConstants.wsBaseUrl.startsWith('ws://') ||
              ApiConstants.wsBaseUrl.startsWith('wss://'),
          isTrue,
        );
      });

      test('wsBaseUrl ends with /ws', () {
        expect(ApiConstants.wsBaseUrl, endsWith('/ws'));
      });

      test('wsBaseUrl uses wss for https and ws for http', () {
        final baseUri = Uri.parse(ApiConstants.baseUrl);
        if (baseUri.scheme == 'https') {
          expect(ApiConstants.wsBaseUrl, startsWith('wss://'));
        } else {
          expect(ApiConstants.wsBaseUrl, startsWith('ws://'));
        }
      });
    });

    group('Auth Endpoints', () {
      test('signUp endpoint', () {
        expect(ApiConstants.signUp, equals('/auth/signup'));
      });

      test('login endpoint', () {
        expect(ApiConstants.login, equals('/auth/login'));
      });

      test('refresh endpoint', () {
        expect(ApiConstants.refresh, equals('/auth/refresh'));
      });

      test('logout endpoint', () {
        expect(ApiConstants.logout, equals('/auth/logout'));
      });
    });

    group('User Endpoints', () {
      test('users endpoint', () {
        expect(ApiConstants.users, equals('/users'));
      });

      test('userSearch endpoint', () {
        expect(ApiConstants.userSearch, equals('/users/search'));
      });
    });

    group('Friend Endpoints', () {
      test('friends endpoint', () {
        expect(ApiConstants.friends, equals('/friends'));
      });

      test('friendRequests endpoint', () {
        expect(ApiConstants.friendRequests, equals('/friends/requests'));
      });
    });

    group('Chat Endpoints', () {
      test('chatRooms endpoint', () {
        expect(ApiConstants.chatRooms, equals('/chat/rooms'));
      });

      test('chatMessages endpoint', () {
        expect(ApiConstants.chatMessages, equals('/chat/messages'));
      });

      test('chatReactions endpoint', () {
        expect(ApiConstants.chatReactions, equals('/chat/reactions'));
      });
    });

    group('Block & Report Endpoints', () {
      test('blocks endpoint', () {
        expect(ApiConstants.blocks, equals('/blocks'));
      });

      test('reports endpoint', () {
        expect(ApiConstants.reports, equals('/reports'));
      });
    });

    group('Timeouts', () {
      test('connectTimeout is 30 seconds', () {
        expect(ApiConstants.connectTimeout, equals(const Duration(seconds: 30)));
      });

      test('receiveTimeout is 30 seconds', () {
        expect(ApiConstants.receiveTimeout, equals(const Duration(seconds: 30)));
      });

      test('sendTimeout is 30 seconds', () {
        expect(ApiConstants.sendTimeout, equals(const Duration(seconds: 30)));
      });

      test('all timeouts are positive', () {
        expect(ApiConstants.connectTimeout.inMilliseconds, greaterThan(0));
        expect(ApiConstants.receiveTimeout.inMilliseconds, greaterThan(0));
        expect(ApiConstants.sendTimeout.inMilliseconds, greaterThan(0));
      });
    });
  });
}
