import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return '비밀번호는 ${AppConstants.minPasswordLength}자 이상이어야 합니다';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return '비밀번호는 ${AppConstants.maxPasswordLength}자 이하이어야 합니다';
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }

    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }

    return null;
  }

  static String? nickname(String? value) {
    if (value == null || value.isEmpty) {
      return '닉네임을 입력해주세요';
    }

    if (value.length < AppConstants.minNicknameLength) {
      return '닉네임은 ${AppConstants.minNicknameLength}자 이상이어야 합니다';
    }

    if (value.length > AppConstants.maxNicknameLength) {
      return '닉네임은 ${AppConstants.maxNicknameLength}자 이하이어야 합니다';
    }

    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }
    return null;
  }
}
