import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/data/models/auth_models.dart';
import 'package:co_talk_flutter/domain/entities/auth_token.dart';

void main() {
  group('SignUpRequest', () {
    test('creates request with required fields', () {
      const request = SignUpRequest(
        email: 'test@example.com',
        password: 'password123',
        nickname: 'TestUser',
      );

      expect(request.email, 'test@example.com');
      expect(request.password, 'password123');
      expect(request.nickname, 'TestUser');
    });

    test('toJson returns correct map', () {
      const request = SignUpRequest(
        email: 'test@example.com',
        password: 'password123',
        nickname: 'TestUser',
      );

      final json = request.toJson();

      expect(json['email'], 'test@example.com');
      expect(json['password'], 'password123');
      expect(json['nickname'], 'TestUser');
    });

    test('fromJson creates request correctly', () {
      final json = {
        'email': 'test@example.com',
        'password': 'password123',
        'nickname': 'TestUser',
      };

      final request = SignUpRequest.fromJson(json);

      expect(request.email, 'test@example.com');
      expect(request.password, 'password123');
      expect(request.nickname, 'TestUser');
    });
  });

  group('SignUpResponse', () {
    test('creates response with required fields', () {
      const response = SignUpResponse(
        userId: 1,
        message: 'Success',
      );

      expect(response.userId, 1);
      expect(response.message, 'Success');
    });

    test('toJson returns correct map', () {
      const response = SignUpResponse(
        userId: 1,
        message: 'Success',
      );

      final json = response.toJson();

      expect(json['userId'], 1);
      expect(json['message'], 'Success');
    });

    test('fromJson creates response correctly', () {
      final json = {
        'userId': 1,
        'message': 'Success',
      };

      final response = SignUpResponse.fromJson(json);

      expect(response.userId, 1);
      expect(response.message, 'Success');
    });
  });

  group('LoginRequest', () {
    test('creates request with required fields', () {
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(request.email, 'test@example.com');
      expect(request.password, 'password123');
    });

    test('toJson returns correct map', () {
      const request = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );

      final json = request.toJson();

      expect(json['email'], 'test@example.com');
      expect(json['password'], 'password123');
    });

    test('fromJson creates request correctly', () {
      final json = {
        'email': 'test@example.com',
        'password': 'password123',
      };

      final request = LoginRequest.fromJson(json);

      expect(request.email, 'test@example.com');
      expect(request.password, 'password123');
    });
  });

  group('AuthTokenResponse', () {
    test('creates response with required fields', () {
      const response = AuthTokenResponse(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        expiresIn: 3600,
      );

      expect(response.accessToken, 'access_token_123');
      expect(response.refreshToken, 'refresh_token_456');
      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, 3600);
    });

    test('creates response with custom token type', () {
      const response = AuthTokenResponse(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        tokenType: 'JWT',
        expiresIn: 3600,
      );

      expect(response.tokenType, 'JWT');
    });

    test('toJson returns correct map', () {
      const response = AuthTokenResponse(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        expiresIn: 3600,
      );

      final json = response.toJson();

      expect(json['accessToken'], 'access_token_123');
      expect(json['refreshToken'], 'refresh_token_456');
      expect(json['tokenType'], 'Bearer');
      expect(json['expiresIn'], 3600);
    });

    test('fromJson creates response correctly', () {
      final json = {
        'accessToken': 'access_token_123',
        'refreshToken': 'refresh_token_456',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
      };

      final response = AuthTokenResponse.fromJson(json);

      expect(response.accessToken, 'access_token_123');
      expect(response.refreshToken, 'refresh_token_456');
    });

    group('toEntity', () {
      test('converts to AuthToken entity', () {
        const response = AuthTokenResponse(
          accessToken: 'access_token_123',
          refreshToken: 'refresh_token_456',
          tokenType: 'Bearer',
          expiresIn: 3600,
        );

        final entity = response.toEntity();

        expect(entity, isA<AuthToken>());
        expect(entity.accessToken, 'access_token_123');
        expect(entity.refreshToken, 'refresh_token_456');
        expect(entity.tokenType, 'Bearer');
        expect(entity.expiresIn, 3600);
      });
    });
  });

  group('TokenRefreshRequest', () {
    test('creates request with required fields', () {
      const request = TokenRefreshRequest(
        refreshToken: 'refresh_token_456',
      );

      expect(request.refreshToken, 'refresh_token_456');
    });

    test('toJson returns correct map', () {
      const request = TokenRefreshRequest(
        refreshToken: 'refresh_token_456',
      );

      final json = request.toJson();

      expect(json['refreshToken'], 'refresh_token_456');
    });

    test('fromJson creates request correctly', () {
      final json = {
        'refreshToken': 'refresh_token_456',
      };

      final request = TokenRefreshRequest.fromJson(json);

      expect(request.refreshToken, 'refresh_token_456');
    });
  });
}
