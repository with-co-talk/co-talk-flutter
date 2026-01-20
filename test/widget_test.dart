import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    testWidgets('light theme applies correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      final theme = Theme.of(tester.element(find.text('Test')));
      expect(theme.brightness, Brightness.light);
    });

    testWidgets('dark theme applies correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Text('Test'),
          ),
        ),
      );

      final theme = Theme.of(tester.element(find.text('Test')));
      expect(theme.brightness, Brightness.dark);
    });
  });
}
