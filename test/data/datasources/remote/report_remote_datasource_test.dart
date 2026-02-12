import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/network/dio_client.dart';
import 'package:co_talk_flutter/data/datasources/remote/report_remote_datasource.dart';
import 'package:co_talk_flutter/data/models/report_model.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockDioClient;
  late ReportRemoteDataSourceImpl datasource;

  setUp(() {
    mockDioClient = MockDioClient();
    datasource = ReportRemoteDataSourceImpl(mockDioClient);
  });

  group('ReportRemoteDataSource', () {
    group('reportUser', () {
      test('sends POST request with correct data including description', () async {
        when(() => mockDioClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        await datasource.reportUser(
          reportedUserId: 42,
          reason: 'SPAM',
          description: 'Test description',
        );

        verify(() => mockDioClient.post(
          '/reports/users',
          data: {
            'reportedUserId': 42,
            'reason': 'SPAM',
            'description': 'Test description',
          },
        )).called(1);
      });

      test('omits description when null', () async {
        when(() => mockDioClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        await datasource.reportUser(
          reportedUserId: 42,
          reason: 'HARASSMENT',
        );

        verify(() => mockDioClient.post(
          '/reports/users',
          data: {
            'reportedUserId': 42,
            'reason': 'HARASSMENT',
          },
        )).called(1);
      });

      test('omits description when empty string', () async {
        when(() => mockDioClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        await datasource.reportUser(
          reportedUserId: 42,
          reason: 'HARASSMENT',
          description: '',
        );

        verify(() => mockDioClient.post(
          '/reports/users',
          data: {
            'reportedUserId': 42,
            'reason': 'HARASSMENT',
          },
        )).called(1);
      });
    });

    group('reportMessage', () {
      test('sends POST request with correct data including description', () async {
        when(() => mockDioClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        await datasource.reportMessage(
          reportedMessageId: 99,
          reason: 'INAPPROPRIATE_CONTENT',
          description: 'Offensive message',
        );

        verify(() => mockDioClient.post(
          '/reports/messages',
          data: {
            'reportedMessageId': 99,
            'reason': 'INAPPROPRIATE_CONTENT',
            'description': 'Offensive message',
          },
        )).called(1);
      });

      test('omits description when null', () async {
        when(() => mockDioClient.post(
          any(),
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response(
          data: {'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        await datasource.reportMessage(
          reportedMessageId: 99,
          reason: 'INAPPROPRIATE_CONTENT',
        );

        verify(() => mockDioClient.post(
          '/reports/messages',
          data: {
            'reportedMessageId': 99,
            'reason': 'INAPPROPRIATE_CONTENT',
          },
        )).called(1);
      });
    });

    group('getMyReports', () {
      test('returns list of reports', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
          data: {
            'reports': [
              {
                'id': 1,
                'type': 'USER',
                'reason': 'SPAM',
                'status': 'PENDING',
                'createdAt': '2024-01-01T00:00:00Z',
              },
              {
                'id': 2,
                'type': 'MESSAGE',
                'reason': 'HARASSMENT',
                'description': 'Test',
                'status': 'REVIEWED',
                'createdAt': '2024-01-02T00:00:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final reports = await datasource.getMyReports();

        expect(reports, isA<List<ReportModel>>());
        expect(reports.length, 2);
        expect(reports[0].id, 1);
        expect(reports[0].type, 'USER');
        expect(reports[0].reason, 'SPAM');
        expect(reports[1].id, 2);
        expect(reports[1].description, 'Test');
      });

      test('returns empty list when no reports', () async {
        when(() => mockDioClient.get(any())).thenAnswer((_) async => Response(
          data: {'reports': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        final reports = await datasource.getMyReports();

        expect(reports, isEmpty);
      });
    });
  });
}
