import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Solo en `--profile`: cada 2 s imprime FPS promedio y peor frame (build+raster) en logcat.
/// Se lee con `adb logcat -s flutter | grep PERF`.
void startPerfLog() {
  if (!kProfileMode) return;
  final frames = <Duration>[];
  var buildUs = 0, rasterUs = 0;
  var window = DateTime.now();
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      frames.add(t.totalSpan);
      buildUs += t.buildDuration.inMicroseconds;
      rasterUs += t.rasterDuration.inMicroseconds;
    }
    final now = DateTime.now();
    final elapsed = now.difference(window);
    if (elapsed.inMilliseconds < 2000) return;
    final worst = frames.reduce((a, b) => a > b ? a : b);
    final avgMs = frames.fold(0, (s, d) => s + d.inMicroseconds) / frames.length / 1000;
    final jank = frames.where((d) => d.inMilliseconds > 16).length;
    debugPrint('PERF fps=${(frames.length / (elapsed.inMilliseconds / 1000)).toStringAsFixed(1)} '
        'avg=${avgMs.toStringAsFixed(1)}ms (build ${(buildUs / frames.length / 1000).toStringAsFixed(1)} / raster ${(rasterUs / frames.length / 1000).toStringAsFixed(1)}) '
        'worst=${worst.inMilliseconds}ms jank=$jank/${frames.length}');
    frames.clear();
    buildUs = 0;
    rasterUs = 0;
    window = now;
  });
}
