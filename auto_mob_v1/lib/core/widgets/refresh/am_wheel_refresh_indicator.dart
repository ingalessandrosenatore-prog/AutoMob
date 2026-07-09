import 'dart:math' as math;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _wheelAsset = 'lib/assets/icons/ruota.svg';

/// Pull-to-refresh riutilizzabile tra feature diverse: avvolge una lista o
/// uno scroll esistente (`ListView`, `SingleChildScrollView`, ...) SENZA
/// ristrutturarli in sliver. Mostra una ruota che gira con un effetto di
/// polvere durante il pull e il caricamento.
///
/// Volutamente indipendente dal pop-up modale di caricamento (`AmStatusDialog`):
/// [onRefresh] va collegato a un evento bloc dedicato che NON passa per lo
/// stato "loading" a tutto schermo (vedi `RefreshRequested`/
/// `DashboardRefreshRequested`), altrimenti i due si sovrapporrebbero.
class AmWheelRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color color;

  const AmWheelRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color = const Color(0xFFFF6B00),
  });

  @override
  State<AmWheelRefreshIndicator> createState() =>
      _AmWheelRefreshIndicatorState();
}

class _AmWheelRefreshIndicatorState extends State<AmWheelRefreshIndicator>
    with SingleTickerProviderStateMixin {
  // Rotazione continua della ruota mentre il refresh e' in corso; durante il
  // pull (prima del rilascio) la rotazione segue invece il progresso del
  // trascinamento, guidato direttamente dall'IndicatorController.
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
    return CustomRefreshIndicator(
      onRefresh: widget.onRefresh,
      builder: (context, child, controller) {
        return Stack(
          children: [
            child,
            PositionedIndicatorContainer(
              controller: controller,
              child: AnimatedBuilder(
                animation: Listenable.merge([controller, _spinCtrl]),
                builder: (context, _) {
                  final pullProgress = controller.value.clamp(0.0, 1.0);
                  final spinning = controller.isLoading;
                  final angle = spinning
                      ? _spinCtrl.value * 2 * math.pi
                      : pullProgress * 2 * math.pi;
                  final active = spinning || controller.isDragging || controller.isArmed;

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
              ),
            ),
          ],
        );
      },
      child: widget.child,
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
