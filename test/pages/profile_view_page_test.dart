import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/di/injection.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:co_talk_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_bloc.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_event.dart';
import 'package:co_talk_flutter/presentation/blocs/profile/profile_state.dart';
import 'package:co_talk_flutter/presentation/pages/profile/profile_view_page.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockProfileBloc mockProfileBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const ProfileUserLoadRequested(userId: 1));
  });

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    mockAuthBloc = MockAuthBloc();
    if (getIt.isRegistered<ProfileBloc>()) {
      getIt.unregister<ProfileBloc>();
    }
    getIt.registerFactory<ProfileBloc>(() => mockProfileBloc);
  });

  tearDown(() {
    if (getIt.isRegistered<ProfileBloc>()) {
      getIt.unregister<ProfileBloc>();
    }
  });

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const ProfileViewPage(userId: 1),
      ),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  testWidgets('최초 로드 실패 시(user=null) 무한 로딩이 아니라 에러 UI를 보여준다', (tester) async {
    whenListen(
      mockProfileBloc,
      const Stream<ProfileState>.empty(),
      initialState: const ProfileState(
        status: ProfileStatus.failure,
        errorMessage: '프로필을 불러오지 못했습니다',
        viewingUser: null,
      ),
    );
    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();

    // 로딩 스피너가 아니라 에러 메시지가 보여야 한다.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('프로필을 불러오지 못했습니다'), findsOneWidget);
  });

  testWidgets('로드 실패 시 재시도 버튼이 있고, 누르면 다시 로드 이벤트를 보낸다', (tester) async {
    whenListen(
      mockProfileBloc,
      const Stream<ProfileState>.empty(),
      initialState: const ProfileState(
        status: ProfileStatus.failure,
        errorMessage: '프로필을 불러오지 못했습니다',
        viewingUser: null,
      ),
    );
    whenListen(
      mockAuthBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump();

    final retryButton = find.widgetWithText(ElevatedButton, '다시 시도');
    expect(retryButton, findsOneWidget);

    clearInteractions(mockProfileBloc);
    await tester.tap(retryButton);
    await tester.pump();

    verify(
      () => mockProfileBloc.add(const ProfileUserLoadRequested(userId: 1)),
    ).called(1);
    verify(
      () => mockProfileBloc.add(const ProfileHistoryLoadRequested(userId: 1)),
    ).called(1);
  });
}
