import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/auth_token.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class SignUpRequest {
  final String email;
  final String password;
  final String nickname;

  const SignUpRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  factory SignUpRequest.fromJson(Map<String, dynamic> json) =>
      _$SignUpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SignUpRequestToJson(this);
}

@JsonSerializable()
class SignUpResponse {
  final int userId;
  final String message;

  const SignUpResponse({
    required this.userId,
    required this.message,
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) =>
      _$SignUpResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SignUpResponseToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class AuthTokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenResponseToJson(this);

  AuthToken toEntity() {
    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
    );
  }
}

@JsonSerializable()
class TokenRefreshRequest {
  final String refreshToken;

  const TokenRefreshRequest({required this.refreshToken});

  factory TokenRefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$TokenRefreshRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TokenRefreshRequestToJson(this);
}
