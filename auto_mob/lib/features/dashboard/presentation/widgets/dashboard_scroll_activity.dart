import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Tracks both the vertical scroll and vehicle paging, including inertia.
class DashboardScrollActivity extends ValueNotifier<bool> {
  DashboardScrollActivity() : super(false);

  final _positions = <ScrollPosition>{};
  bool _scheduled = false;
  bool _disposed = false;

  void attach(ScrollPosition position) {
    if (_positions.add(position)) {
      position.isScrollingNotifier.addListener(_sync);
      _sync();
    }
  }

  void detach(ScrollPosition position) {
    if (_positions.remove(position)) {
      position.isScrollingNotifier.removeListener(_sync);
      _sync();
    }
  }

  void _sync() {
    if (_disposed) return;
    final scrolling = _positions.any((p) => p.isScrollingNotifier.value);
    if (value == scrolling) return;
    // Attach/detach can happen during layout; never rebuild a sibling there.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (!_scheduled) {
        _scheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scheduled = false;
          _sync();
        });
      }
      return;
    }
    value = scrolling;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final position in _positions) {
      position.isScrollingNotifier.removeListener(_sync);
    }
    _positions.clear();
    super.dispose();
  }
}
