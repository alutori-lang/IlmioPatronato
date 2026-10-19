// Retry schedule for ad loads that failed (no fill, network error, ...).
//
// 30 s, 60 s, 2 min, then every 4 min for as long as the app runs. A
// successful load resets it, so the next failure starts again at 30 s.
import 'dart:async';

class AdRetryBackoff {
  AdRetryBackoff({List<Duration>? delays})
      : delays = delays ??
            const [
              Duration(seconds: 30),
              Duration(seconds: 60),
              Duration(minutes: 2),
              Duration(minutes: 4),
            ];

  /// The last delay repeats forever.
  final List<Duration> delays;

  int _failures = 0;
  Timer? _timer;

  int get failures => _failures;

  bool get isScheduled => _timer?.isActive ?? false;

  /// The delay the next [schedule] call will use.
  Duration get nextDelay =>
      delays[_failures < delays.length ? _failures : delays.length - 1];

  /// Runs [retry] after the next delay. Ignored when one is already pending.
  void schedule(void Function() retry) {
    if (isScheduled) return;
    final delay = nextDelay;
    _failures++;
    _timer = Timer(delay, () {
      _timer = null;
      retry();
    });
  }

  /// Call after a successful load.
  void reset() {
    _failures = 0;
    cancel();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
