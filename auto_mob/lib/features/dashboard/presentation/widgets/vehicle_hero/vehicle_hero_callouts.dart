import 'package:common_ui_widget/common_ui_widget.dart' show AmThemeColors;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/types/enum_pop_up.dart';
import '../../../../vehicle/domain/entities/maintenance_kpi.dart';
import 'vehicle_hero_callout_card.dart';
import 'vehicle_hero_scene.dart';
import 'vehicle_hero_pulse.dart';

class VehicleHeroCallouts extends StatelessWidget {
  const VehicleHeroCallouts({
    super.key,
    required this.scene,
    required this.animation,
    required this.kpis,
    required this.onKpiTap,
  });

  static const duration = Duration(milliseconds: 3700);
  static const arrival = .38;
  static const _starts = [.44, .61, .78];
  static const _lineDuration = .135;
  static const _fadeDuration = .055;

  final VehicleHeroScene scene;
  final Animation<double> animation;
  final List<MaintenanceKpi> kpis;
  final ValueChanged<MaintenanceKpi> onKpiTap;

  @override
  Widget build(BuildContext context) {
    final accent = AmThemeColors.of(context).accent;
    final byType = {for (final kpi in kpis) kpi.type: kpi};
    final timing = byType[EnumPopUp.aggiornaDistribuzione];
    final service = byType[EnumPopUp.aggiornaTagliando];
    final tires = byType[EnumPopUp.aggiornaCambioGomme];
    final rotation = byType[EnumPopUp.pneumaticiInversione];
    if (timing == null && service == null && tires == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final inset = (size.width * .044).clamp(10.0, 26.0);
        final cards = <Widget>[];
        final wires = <VehicleHeroWire>[];

        void add({
          required int index,
          required MaintenanceKpi kpi,
          required String title,
          required String part,
          required List<List<dynamic>> icon,
          required double top,
          MaintenanceKpi? secondary,
          bool right = false,
        }) {
          final card = VehicleHeroCalloutCard(
            title: title,
            icon: icon,
            kpi: kpi,
            secondary: secondary,
            onKpiTap: onKpiTap,
          );
          final width = (size.width * .42).clamp(110.0, 172.0);
          final left = right ? size.width - inset - width : inset;
          final end = Offset(right ? left : left + width, top + 24);
          final start = scene.camera.worldToScreen(scene.anchor(part), size);
          if (start == null) return;
          wires.add(VehicleHeroWire(start, end, _starts[index], _lineDuration));
          cards.add(
            Positioned(
              top: top,
              left: left,
              width: width,
              child: AnimatedBuilder(
                animation: animation,
                child: card,
                builder: (context, child) {
                  final fade =
                      ((animation.value - _starts[index] - _lineDuration) /
                              _fadeDuration)
                          .clamp(0.0, 1.0);
                  if (fade == 0) return const SizedBox.shrink();
                  return Opacity(
                    opacity: fade,
                    child: Transform.translate(
                      offset: Offset(0, (1 - fade) * 6),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (timing != null) {
          add(
            index: 0,
            kpi: timing,
            title: 'Distribuzione',
            part: 'timing_belt',
            icon: HugeIcons.strokeRoundedTools,
            top: size.height * .10,
          );
        }
        if (service != null) {
          add(
            index: 1,
            kpi: service,
            title: 'Tagliando',
            part: 'oil_pan',
            icon: HugeIcons.strokeRoundedTools,
            top: size.height * .79,
          );
        }
        if (tires != null) {
          add(
            index: 2,
            kpi: tires,
            secondary: rotation,
            title: 'Gomme',
            part: 'tire_FL',
            icon: HugeIcons.strokeRoundedTire,
            top: size.height * .71,
            right: true,
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: VehicleHeroPulse(
                  animation: animation,
                  wires: wires,
                  accent: accent,
                ),
              ),
            ),
            ...cards,
          ],
        );
      },
    );
  }
}
