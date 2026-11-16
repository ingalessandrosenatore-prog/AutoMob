import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Starts the intro once the dashboard has scrolled the scene into view.
class VehicleHeroScrollTrigger extends StatefulWidget {
  const VehicleHeroScrollTrigger({
    super.key,
    required this.ready,
    required this.topObstruction,
    required this.onReveal,
    required this.child,
  });

  final bool ready;
  final double topObstruction;
  final VoidCallback onReveal;
  final Widget child;

  @override
  State<VehicleHeroScrollTrigger> createState() =>
      _VehicleHeroScrollTriggerState();
}

class _VehicleHeroScrollTriggerState extends State<VehicleHeroScrollTrigger> {
  ScrollPosition? _position;
  double? _lastPixels;
  bool _scrolled = false;
  bool _pending = false;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (_position == position) return;
    _detach();
    _position = position;
    _lastPixels = position != null && position.hasPixels
        ? position.pixels
        : null;
    _scrolled = false;
    if (!_revealed && position != null) {
      position.addListener(_onScroll);
      position.isScrollingNotifier.addListener(_checkAfterLayout);
    }
  }

  @override
  void didUpdateWidget(VehicleHeroScrollTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready && _scrolled) _checkAfterLayout();
  }

  void _onScroll() {
    final position = _position!;
    if (!position.hasContentDimensions) return;
    final pixels = position.pixels
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    final previous = _lastPixels;
    _lastPixels = pixels;
    if (previous == null || previous == pixels) return;
    _scrolled = true;
    _checkAfterLayout();
  }

  void _checkAfterLayout() {
    if (_pending || _revealed || !_scrolled || !widget.ready) return;
    _pending = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      _pending = false;
      if (!mounted ||
          !_scrolled ||
          !widget.ready ||
          _position?.isScrollingNotifier.value != false) {
        return;
      }
      final target = context.findRenderObject();
      if (target is! RenderBox || !target.hasSize) return;
      final viewport = RenderAbstractViewport.maybeOf(target);
      if (viewport == null) return;
      final area = MatrixUtils.transformRect(
        target.getTransformTo(viewport),
        Offset.zero & target.size,
      );
      final unobstructed = Rect.fromLTRB(
        0,
        widget.topObstruction,
        viewport.paintBounds.right,
        viewport.paintBounds.bottom,
      );
      final visible = area.intersect(unobstructed);
      final threshold = math.min(area.height, unobstructed.height) / 2;
      if (visible.isEmpty || visible.height < threshold) return;
      _revealed = true;
      _detach();
      widget.onReveal();
    });
    // A stationary drag can end without triggering a new layout.
    binding.ensureVisualUpdate();
  }

  void _detach() {
    _position?.removeListener(_onScroll);
    _position?.isScrollingNotifier.removeListener(_checkAfterLayout);
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
