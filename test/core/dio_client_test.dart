import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/core/network/auth_interceptor.dart';
import 'package:co_talk_flutter/core/network/certificate_pinning_interceptor.dart';
import 'package:co_talk_flutter/core/constants/api_constants.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockDio extends Mock implements Dio {}

void main() {
  late DioClient dioClient;
  late MockAuthLocalDataSource mockAuthLocalDataSource;
  late AuthInterceptor authInterceptor;
  late CertificatePinningInterceptor certificatePinningInterceptor;

  setUp(() {
    mockAuthLocalDataSource = MockAuthLocalDataSource();
    authInterceptor = AuthInterceptor(mockAuthLocalDataSource);
    certificatePinningInterceptor = CertificatePinningInterceptor();
    dioClient = DioClient(authInterceptor, certificatePinningInterceptor);
  });

  group('DioClient', () {
    group('initialization', () {
      test('creates Dio instance with correct base options', () {
        expect(dioClient.dio, isA<Dio>());
        expect(dioClient.dio.options.baseUrl, isNotEmpty);
      });

      test('has correct base URL', () {
        expect(dioClient.dio.options.baseUrl, equals(ApiConstants.apiBaseUrl));
      });

      test('has correct connect timeout', () {
        expect(
          dioClient.dio.options.connectTimeout,
          equals(ApiConstants.connectTimeout),
        );
      });

      test('has correct receive timeout', () {
        expect(
          dioClient.dio.options.receiveTimeout,
          equals(ApiConstants.receiveTimeout),
        );
      });

      test('has correct send timeout', () {
        expect(
          dioClient.dio.options.sendTimeout,
          equals(ApiConstants.sendTimeout),
        );
      });

      test('has Content-Type header set to application/json', () {
        expect(
          dioClient.dio.options.headers['Content-Type'],
          equals('application/json'),
        );
      });

      test('has Accept header set to application/json', () {
        expect(
          dioClient.dio.options.headers['Accept'],
          equals('application/json'),
        );
      });
    });

    group('interceptors', () {
      test('has auth interceptor', () {
        expect(
          dioClient.dio.interceptors.any((i) => i is AuthInterceptor),
          isTrue,
        );
      });

      test('has log interceptor', () {
        expect(
          dioClient.dio.interceptors.any((i) => i is LogInterceptor),
          isTrue,
        );
      });

      test('has at least 2 interceptors', () {
        expect(dioClient.dio.interceptors.length, greaterThanOrEqualTo(2));
      });
    });

    group('dio getter', () {
      test('returns same instance', () {
        final dio1 = dioClient.dio;
        final dio2 = dioClient.dio;
        expect(identical(dio1, dio2), isTrue);
      });

      test('returns Dio instance', () {
        expect(dioClient.dio, isA<Dio>());
      });
    });

    group('HTTP methods', () {
      test('get method exists', () {
        expect(dioClient.get, isNotNull);
      });

      test('post method exists', () {
        expect(dioClient.post, isNotNull);
      });

      test('put method exists', () {
        expect(dioClient.put, isNotNull);
      });

      test('patch method exists', () {
        expect(dioClient.patch, isNotNull);
      });

      test('delete method exists', () {
        expect(dioClient.delete, isNotNull);
      });
    });
  });
}
