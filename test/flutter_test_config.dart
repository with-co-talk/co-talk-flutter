import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// golden 픽셀 비교 허용 오차.
///
/// 동일 golden PNG를 macOS(개발)와 Linux(CI) 양쪽에서 검증하는데, 두 OS의
/// 글리프 안티앨리어싱 차이로 텍스트가 많은 이미지에서 ~1-2%의 픽셀 diff가
/// 불가피하다(관측값 1.49%). 폰트를 적재해도 서브픽셀 렌더 차이는 남는다.
/// 레이아웃/색상 등 실질적 UI 회귀는 이 임계값을 크게 초과하므로 여전히 잡힌다.
const double _goldenDiffTolerance = 0.03;

/// 모든 테스트 실행 전 공통 설정.
///
/// 1. golden 테스트가 환경(플러터 SDK·렌더 엔진)에 따라 픽셀이 흔들리지 않도록,
///    앱이 번들하는 Pretendard 폰트를 테스트 폰트 레지스트리에 미리 적재한다.
///    폰트를 적재하지 않으면 기본 테스트 폰트(Ahem, 네모 박스)로 렌더되어
///    베이스라인이 toolchain 종속적으로 깨질 수 있다.
/// 2. 남는 OS 간 서브픽셀 차이를 흡수하도록 golden comparator에 허용 오차를 둔다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadPretendard();

  // flutter_test_config는 테스트 파일마다 실행되므로, 이 시점의 기본
  // LocalFileComparator.basedir는 해당 파일 디렉토리로 올바르게 설정돼 있다.
  final GoldenFileComparator base = goldenFileComparator;
  if (base is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenComparator(base.basedir);
  }

  await testMain();
}

/// [_goldenDiffTolerance] 이하의 픽셀 차이는 통과로 처리하는 golden comparator.
class _TolerantGoldenComparator extends LocalFileComparator {
  /// [LocalFileComparator]는 생성자 인자를 "테스트 파일"로 보고 basedir로
  /// 그 파일의 디렉토리(`resolve('./')`)를 쓴다. 디렉토리 Uri를 그대로 주면
  /// 마지막 세그먼트가 잘리므로, 더미 파일명을 붙여 basedir를 보존한다.
  _TolerantGoldenComparator(Uri basedir)
      : super(basedir.resolve('flutter_test_config.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _goldenDiffTolerance) {
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
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
