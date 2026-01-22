import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error when email is null', () {
        expect(Validators.email(null), '이메일을 입력해주세요');
      });

      test('returns error when email is empty', () {
        expect(Validators.email(''), '이메일을 입력해주세요');
      });

      test('returns error for invalid email format', () {
        expect(Validators.email('invalid'), '올바른 이메일 형식이 아닙니다');
        expect(Validators.email('invalid@'), '올바른 이메일 형식이 아닙니다');
        expect(Validators.email('@example.com'), '올바른 이메일 형식이 아닙니다');
        expect(Validators.email('invalid.com'), '올바른 이메일 형식이 아닙니다');
      });

      test('returns null for valid email', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name@domain.co.kr'), isNull);
        expect(Validators.email('user+tag@example.org'), isNull);
      });
    });

    group('password', () {
      test('returns error when password is null', () {
        expect(Validators.password(null), '비밀번호를 입력해주세요');
      });

      test('returns error when password is empty', () {
        expect(Validators.password(''), '비밀번호를 입력해주세요');
      });

      test('returns error when password is too short', () {
        expect(Validators.password('12345'), contains('이상이어야'));
      });

      test('returns error when password is too long', () {
        final longPassword = 'a' * 129;
        expect(Validators.password(longPassword), contains('이하이어야'));
      });

      test('returns null for valid password', () {
        expect(Validators.password('password123'), isNull);
        expect(Validators.password('ValidPass!@#'), isNull);
      });
    });

    group('confirmPassword', () {
      test('returns error when confirm password is null', () {
        expect(
          Validators.confirmPassword(null, 'password'),
          '비밀번호 확인을 입력해주세요',
        );
      });

      test('returns error when confirm password is empty', () {
        expect(
          Validators.confirmPassword('', 'password'),
          '비밀번호 확인을 입력해주세요',
        );
      });

      test('returns error when passwords do not match', () {
        expect(
          Validators.confirmPassword('different', 'password'),
          '비밀번호가 일치하지 않습니다',
        );
      });

      test('returns null when passwords match', () {
        expect(Validators.confirmPassword('password123', 'password123'), isNull);
      });
    });

    group('nickname', () {
      test('returns error when nickname is null', () {
        expect(Validators.nickname(null), '닉네임을 입력해주세요');
      });

      test('returns error when nickname is empty', () {
        expect(Validators.nickname(''), '닉네임을 입력해주세요');
      });

      test('returns error when nickname is too short', () {
        expect(Validators.nickname('a'), contains('이상이어야'));
      });

      test('returns error when nickname is too long', () {
        final longNickname = 'a' * 21;
        expect(Validators.nickname(longNickname), contains('이하이어야'));
      });

      test('returns null for valid nickname', () {
        expect(Validators.nickname('User123'), isNull);
        expect(Validators.nickname('홍길동'), isNull);
      });
    });

    group('required', () {
      test('returns error when value is null', () {
        expect(
          Validators.required(null, '필드명'),
          '필드명을(를) 입력해주세요',
        );
      });

      test('returns error when value is empty', () {
        expect(
          Validators.required('', '필드명'),
          '필드명을(를) 입력해주세요',
        );
      });

      test('returns null for non-empty value', () {
        expect(Validators.required('value', '필드명'), isNull);
      });
    });

    group('containsKorean', () {
      test('returns false when value is null', () {
        expect(Validators.containsKorean(null), isFalse);
      });

      test('returns false when value is empty', () {
        expect(Validators.containsKorean(''), isFalse);
      });

      test('returns false for English only', () {
        expect(Validators.containsKorean('password123'), isFalse);
        expect(Validators.containsKorean('Test!@#\$%'), isFalse);
      });

      test('returns true for Korean complete characters (가-힣)', () {
        expect(Validators.containsKorean('비밀번호'), isTrue);
        expect(Validators.containsKorean('password한글'), isTrue);
      });

      test('returns true for Korean jamo (ㄱ-ㅎ, ㅏ-ㅣ)', () {
        expect(Validators.containsKorean('ㅜㅗㅜ123'), isTrue);
        expect(Validators.containsKorean('ㅋㅋㅋ'), isTrue);
        expect(Validators.containsKorean('ㅎㅎ'), isTrue);
        expect(Validators.containsKorean('passㅁword'), isTrue);
      });

      test('returns false for numbers and special characters only', () {
        expect(Validators.containsKorean('123456'), isFalse);
        expect(Validators.containsKorean('!@#\$%^&*()'), isFalse);
      });
    });
  });
}
