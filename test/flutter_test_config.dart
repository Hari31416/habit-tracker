// Cross-platform golden tolerance for macOS (local) vs Linux (CI) font/raster diffs.
// Regenerating goldens: flutter test test/ui/ui_goldens_test.dart --update-goldens

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Anchor goldens relative to test/ui/ so ../goldens/ui resolves to test/goldens/ui/.
  final testUiFile =
      File('${Directory.current.path}/test/ui/ui_goldens_test.dart');
  goldenFileComparator = _TolerantGoldenComparator(
    testUiFile.uri,
    maxDiffPercent: 5.0,
  );
  await testMain();
}

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {required this.maxDiffPercent});

  /// Allowed percentage of differing pixels (e.g. 5.0 = 5%).
  /// Flutter's ComparisonResult.diffPercent is on a 0..100 scale.
  final double maxDiffPercent;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    if (result.diffPercent <= maxDiffPercent) {
      return true;
    }
    throw FlutterError(
      'Golden test failed with diff of ${result.diffPercent.toStringAsFixed(2)}% '
      '(allowed <= ${maxDiffPercent.toStringAsFixed(2)}%):\n$result',
    );
  }
}
