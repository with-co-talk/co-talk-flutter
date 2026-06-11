import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/core/utils/app_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  void expectHaptic(String type) {
    expect(calls.length, 1);
    expect(calls.single.method, 'HapticFeedback.vibrate');
    expect(calls.single.arguments, type);
  }

  test('light() → lightImpact', () {
    AppHaptics.light();
    expectHaptic('HapticFeedbackType.lightImpact');
  });

  test('medium() → mediumImpact', () {
    AppHaptics.medium();
    expectHaptic('HapticFeedbackType.mediumImpact');
  });

  test('selection() → selectionClick', () {
    AppHaptics.selection();
    expectHaptic('HapticFeedbackType.selectionClick');
  });

  test('heavy() → heavyImpact', () {
    AppHaptics.heavy();
    expectHaptic('HapticFeedbackType.heavyImpact');
  });
}
