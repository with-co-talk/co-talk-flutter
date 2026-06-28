import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 모든 테스트 실행 전 공통 설정.
///
/// golden 테스트가 환경(플러터 SDK·렌더 엔진)에 따라 픽셀이 흔들리지 않도록,
/// 앱이 번들하는 Pretendard 폰트를 테스트 폰트 레지스트리에 미리 적재한다.
/// 폰트를 적재하지 않으면 기본 테스트 폰트(Ahem, 네모 박스)로 렌더되어
/// 베이스라인이 toolchain 종속적으로 깨질 수 있다.
///
/// 또한 golden 비교에 작은 허용 오차(3%)를 둔다. 폰트를 고정해도
/// macOS(개발)와 Linux(CI)의 안티앨리어싱·서브픽셀 렌더 차이로 1~2% 수준의
/// 픽셀 드리프트가 발생하기 때문이다. 실제 디자인 변경은 두 자릿수% 차이라
/// 이 임계값으로 충분히 구분된다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadPretendard();
  if (goldenFileComparator is LocalFileComparator) {
    final basedir = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = _TolerantGoldenComparator(basedir, threshold: 0.03);
  }
  await testMain();
}

/// 플랫폼별 AA 드리프트를 흡수하기 위해 임계값 이하 픽셀 차이는 통과시키는 비교기.
class _TolerantGoldenComparator extends LocalFileComparator {
  final double threshold;

  _TolerantGoldenComparator(Uri basedir, {required this.threshold})
      : super(Uri.parse('$basedir/placeholder_test.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= threshold) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
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
