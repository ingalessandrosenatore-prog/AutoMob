import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _wheelAsset = 'lib/assets/icons/ruota.svg';

/// Sliver di pull-to-refresh: a differenza di un overlay (`RefreshIndicator`),
/// [CupertinoSliverRefreshControl] occupa spazio REALE nella lista di sliver
/// e quindi spinge fisicamente giu' tutto cio' che lo segue (inclusa
/// un'eventuale app bar sliver dopo di lui) mentre viene tirato e finche'
/// [onRefresh] non si risolve. Va messo come PRIMO sliver di una
/// `CustomScrollView` che usa `BouncingScrollPhysics` (l'overscroll che
/// triggera il pull non esiste con `ClampingScrollPhysics`, il default
/// Android).
class AmRefreshControlSliver extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Color color;

  const AmRefreshControlSliver({
    super.key,
    required this.onRefresh,
    this.color = const Color(0xFFFF6B00),
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
        return Center(
          child: AmWheelRefreshVisual(
            refreshState: refreshState,
            pulledExtent: pulledExtent,
            refreshTriggerPullDistance: refreshTriggerPullDistance,
            color: color,
          ),
        );
      },
    );
  }
}

/// Ruota che gira + effetto polvere, pilotata dallo stato del
/// [CupertinoSliverRefreshControl]: rotazione proporzionale al pull durante
/// il drag, rotazione continua durante [RefreshIndicatorMode.refresh].
class AmWheelRefreshVisual extends StatefulWidget {
  final RefreshIndicatorMode refreshState;
  final double pulledExtent;
  final double refreshTriggerPullDistance;
  final Color color;

  const AmWheelRefreshVisual({
    super.key,
    required this.refreshState,
    required this.pulledExtent,
    required this.refreshTriggerPullDistance,
    this.color = const Color(0xFFFF6B00),
  });

  @override
  State<AmWheelRefreshVisual> createState() => _AmWheelRefreshVisualState();
}

class _AmWheelRefreshVisualState extends State<AmWheelRefreshVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spinning = widget.refreshState == RefreshIndicatorMode.refresh;
    final pullProgress = widget.refreshTriggerPullDistance <= 0
        ? 0.0
        : (widget.pulledExtent / widget.refreshTriggerPullDistance).clamp(0.0, 1.0);
    final active = widget.refreshState != RefreshIndicatorMode.inactive;

    return AnimatedBuilder(
      animation: _spinCtrl,
      builder: (context, _) {
        final angle = spinning
            ? _spinCtrl.value * 2 * math.pi
            : pullProgress * 2 * math.pi;

        return SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(
            painter: _DustPainter(
              progress: spinning ? _spinCtrl.value : pullProgress,
              active: active,
              color: widget.color,
            ),
            child: Center(
              child: Opacity(
                opacity: pullProgress,
                child: Transform.rotate(
                  angle: angle,
                  child: SvgPicture.asset(
                    _wheelAsset,
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Piccolo effetto "polvere": particelle che si allontanano dal centro e
/// svaniscono, sincronizzate con la rotazione della ruota.
class _DustPainter extends CustomPainter {
  static const int _particleCount = 6;
  static const double _minRadius = 12.0;
  static const double _maxRadius = 22.0;

  final double progress;
  final bool active;
  final Color color;

  _DustPainter({
    required this.progress,
    required this.active,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _particleCount; i++) {
      final t = (progress + i / _particleCount) % 1.0;
      final angle = (2 * math.pi / _particleCount) * i + progress * 2 * math.pi;
      final distance = _minRadius + (_maxRadius - _minRadius) * t;
      final offset = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final alpha = (1 - t).clamp(0.0, 1.0) * 0.55;

      canvas.drawCircle(
        offset,
        1.6,
        paint..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_DustPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.color != color;
}
