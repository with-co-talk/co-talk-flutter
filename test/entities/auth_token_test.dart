import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/domain/entities/auth_token.dart';

void main() {
  group('AuthToken', () {
    test('creates auth token with required fields', () {
      const token = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        expiresIn: 3600,
      );

      expect(token.accessToken, 'access_token_123');
      expect(token.refreshToken, 'refresh_token_456');
      expect(token.tokenType, 'Bearer');
      expect(token.expiresIn, 3600);
    });

    test('creates auth token with custom token type', () {
      const token = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        tokenType: 'JWT',
        expiresIn: 3600,
      );

      expect(token.tokenType, 'JWT');
    });

    test('equality works correctly', () {
      const token1 = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        expiresIn: 3600,
      );

      const token2 = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        expiresIn: 3600,
      );

      const token3 = AuthToken(
        accessToken: 'different_token',
        refreshToken: 'refresh_token_456',
        expiresIn: 3600,
      );

      expect(token1, equals(token2));
      expect(token1, isNot(equals(token3)));
    });

    test('props returns correct list', () {
      const token = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_456',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      expect(token.props.length, 4);
      expect(token.props, contains('access_token_123'));
      expect(token.props, contains('refresh_token_456'));
      expect(token.props, contains('Bearer'));
      expect(token.props, contains(3600));
    });
  });
}
