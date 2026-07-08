import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_colors.dart';
import 'package:co_talk_flutter/core/theme/app_theme.dart';
import 'package:co_talk_flutter/l10n/app_localizations.dart';
import 'package:co_talk_flutter/presentation/pages/profile/widgets/profile_form_fields.dart';

void main() {
  Widget createWidget({required ThemeData theme, String statusText = ''}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProfileFormFields(
            nicknameController: TextEditingController(),
            statusMessageController: TextEditingController(text: statusText),
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

  testWidgets('라이트 모드 글자수 초과 경고는 어두운 경고색(warningDark)을 쓴다', (tester) async {
    // warning(0xFFE0A458)은 밝은 샌드 앰버라 라이트 모드의 옅은 틴트 배경 위에서
    // 대비가 부족하다. 라이트에서는 warningDark, 다크에서는 warning을 써야 한다.
    final longText = 'a' * 55;

    await tester.pumpWidget(
        createWidget(theme: AppTheme.lightTheme, statusText: longText));
    await tester.pump();

    final counter = tester.widget<Text>(find.text('55/60'));
    expect(counter.style?.color?.toARGB32(), AppColors.warningDark.toARGB32());

    await tester.pumpWidget(
        createWidget(theme: AppTheme.darkTheme, statusText: longText));
    // 같은 트리에서 테마 교체 시 AnimatedTheme 전환이 끝나야 brightness가 바뀐다.
    await tester.pumpAndSettle();

    final darkCounter = tester.widget<Text>(find.text('55/60'));
    expect(darkCounter.style?.color?.toARGB32(), AppColors.warning.toARGB32());
  });
}
