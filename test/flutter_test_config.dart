// Cross-platform golden tolerance for macOS (local) vs Linux (CI) font/raster diffs.
// Regenerating goldens: flutter test test/ui/ui_goldens_test.dart --update-goldens

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Anchor goldens relative to test/ui/ so ../goldens/ui resolves to test/goldens/ui/.
  final testUiFile = File('${Directory.current.path}/test/ui/ui_goldens_test.dart');
  goldenFileComparator = _TolerantGoldenComparator(
    testUiFile.uri,
    pixelDiffFraction: 0.005,
  );
  await testMain();
}

class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {required this.pixelDiffFraction});

  /// Allowed fraction of differing pixels (0.005 = 0.5%).
  final double pixelDiffFraction;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;
    // diffPercent is already a 0..1 fraction in Flutter's ComparisonResult.
    if (result.diffPercent <= pixelDiffFraction) {
      return true;
    }
    throw FlutterError(result.toString());
  }
}
