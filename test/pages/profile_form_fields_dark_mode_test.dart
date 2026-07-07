import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_colors.dart';
import 'package:co_talk_flutter/core/theme/app_theme.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/pages/profile/widgets/profile_form_fields.dart';

void main() {
  Widget createWidget({required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProfileFormFields(
            nicknameController: TextEditingController(),
            statusMessageController: TextEditingController(),
            email: 'test@test.com',
          ),
        ),
      ),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  // 라이트 전용 grey shade가 다크 모드에서 그대로 남아 있으면
  // 밝은 배경 + 밝은 텍스트로 대비가 깨진다.
  List<Container> containersWithColor(WidgetTester tester, Color color) {
    return tester
        .widgetList<Container>(find.byType(Container))
        .where(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).color == color,
        )
        .toList();
  }

  testWidgets('다크 모드에서 라이트 전용 grey[50] 배경을 쓰지 않는다', (tester) async {
    await tester.pumpWidget(createWidget(theme: AppTheme.darkTheme));
    await tester.pump();

    expect(containersWithColor(tester, Colors.grey[50]!), isEmpty);
    expect(containersWithColor(tester, Colors.grey[100]!), isEmpty);
    expect(containersWithColor(tester, Colors.grey[200]!), isEmpty);
  });

  testWidgets('다크 모드에서 입력 필드 컨테이너가 다크 토큰 배경을 쓴다', (tester) async {
    await tester.pumpWidget(createWidget(theme: AppTheme.darkTheme));
    await tester.pump();

    expect(
      containersWithColor(tester, AppColors.backgroundDark),
      isNotEmpty,
      reason: '입력 필드 배경은 다크 모드에서 backgroundDark 토큰이어야 한다',
    );
  });

  testWidgets('라이트 모드에서 입력 필드 컨테이너가 라이트 토큰 배경을 쓴다', (tester) async {
    await tester.pumpWidget(createWidget(theme: AppTheme.lightTheme));
    await tester.pump();

    expect(containersWithColor(tester, AppColors.background), isNotEmpty);
  });
}
