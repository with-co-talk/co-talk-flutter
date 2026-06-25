import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 모든 테스트 실행 전 공통 설정.
///
/// golden 테스트가 환경(플러터 SDK·렌더 엔진)에 따라 픽셀이 흔들리지 않도록,
/// 앱이 번들하는 Pretendard 폰트를 테스트 폰트 레지스트리에 미리 적재한다.
/// 폰트를 적재하지 않으면 기본 테스트 폰트(Ahem, 네모 박스)로 렌더되어
/// 베이스라인이 toolchain 종속적으로 깨질 수 있다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadPretendard();
  await testMain();
}

Future<void> _loadPretendard() async {
  const fontFiles = <String>[
    'assets/fonts/Pretendard-Regular.ttf',
    'assets/fonts/Pretendard-Medium.ttf',
    'assets/fonts/Pretendard-SemiBold.ttf',
    'assets/fonts/Pretendard-Bold.ttf',
  ];

  final loader = FontLoader('Pretendard');
  for (final path in fontFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final Uint8List bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}
