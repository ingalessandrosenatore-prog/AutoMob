import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import '../../../../vehicle/domain/entities/maintenance_kpi.dart';
import '../../../../vehicle/domain/entities/vehicle_maintenance_setting.dart';
import 'vehicle_hero_callout_card.dart';
import 'vehicle_hero_callouts.dart';
import 'vehicle_hero_card_pose.dart';
import 'vehicle_hero_connectors.dart';
import 'vehicle_hero_layout.dart';
import 'vehicle_hero_scene.dart';

class VehicleHeroStage extends StatefulWidget {
  const VehicleHeroStage({
    super.key,
    required this.scene,
    required this.loading,
    required this.callouts,
    required this.onKpiTap,
  });

  final VehicleHeroScene? scene;
  final bool loading;
  final List<VehicleHeroCallout> callouts;
  final ValueChanged<MaintenanceKpi> onKpiTap;

  @override
  State<VehicleHeroStage> createState() => _VehicleHeroStageState();
}

class _VehicleHeroStageState extends State<VehicleHeroStage>
    with SingleTickerProviderStateMixin {
  late final _rotation = AnimationController(vsync: this);

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  void _settle(double target) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _rotation.value = target;
    } else {
      _rotation.animateTo(
        target,
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(12) / 12,
    );
    final callouts = widget.callouts;
    final colors = [for (final entry in callouts) _zoneColor(context, entry)];
    final scene = widget.scene;
    scene?.highlight({
      for (var index = 0; index < callouts.length; index++)
        for (final mesh in callouts[index].meshes)
          mesh: _meshColor(context, callouts[index], mesh, colors[index]),
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = VehicleHeroLayout(
          width: constraints.maxWidth,
          items: [
            for (final card in callouts)
              (
                slot: card.slot,
                height: VehicleHeroCalloutCard.height(card, scale),
              ),
          ],
        );
        final orbit = scene?.orbitFor(layout.viewport.size);
        final front = orbit?.cameraAt(0);
        final rear = orbit?.cameraAt(1);
        final hasRear = callouts.any((card) => card.isRear || card.isTires);
        final poses = <VehicleHeroCardPose>[];
        for (var index = 0; index < callouts.length; index++) {
          final card = callouts[index];
          final anchor = card.anchor;
          poses.add(
            VehicleHeroCardPose(
              rest: layout.cards[index],
              rearRest: layout.rearCards[index] == layout.cards[index]
                  ? null
                  : layout.rearCards[index],
              viewport: layout.viewport,
              rear: card.isRear || card.isTires,
              keepsFocus: card.slot == VehicleHeroSlot.brakes,
              backgroundOpacity: switch (card.slot) {
                VehicleHeroSlot.upperLeft || VehicleHeroSlot.lowerLeft => .24,
                VehicleHeroSlot.lowerRight when card.isTires => .44,
                VehicleHeroSlot.belowBrakes
                    when card.kpi.group == VehicleMaintenanceGroup.gearbox =>
                  .27,
                VehicleHeroSlot.belowBrakes => .16,
                _ => .09,
              },
              anchor: anchor == null ? null : scene?.anchor(anchor),
              frontCamera: front,
              rearCamera: rear,
              wireEdge: switch (card.slot) {
                VehicleHeroSlot.upperLeft => VehicleHeroWireEdge.bottom,
                VehicleHeroSlot.lowerLeft ||
                VehicleHeroSlot.lowerRight => VehicleHeroWireEdge.top,
                _ => VehicleHeroWireEdge.nearest,
              },
            ),
          );
        }
        final cards = [
          for (var index = 0; index < callouts.length; index++)
            VehicleHeroCalloutCard(
              callout: callouts[index],
              scale: scale,
              accent: colors[index],
              onKpiTap: widget.onKpiTap,
            ),
        ];
        return SizedBox(
          height: layout.height,
          child: Semantics(
            label: 'Vista 3D del veicolo',
            onIncrease: scene == null ? null : () => _settle(1),
            onDecrease: scene == null ? null : () => _settle(0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: scene == null
                  ? null
                  : (_) => _rotation.stop(),
              onHorizontalDragUpdate: scene == null
                  ? null
                  : (event) => _rotation.value -= event.delta.dx / 124,
              onHorizontalDragEnd: scene == null
                  ? null
                  : (event) {
                      final speed = event.primaryVelocity ?? 0;
                      _settle(
                        speed.abs() > 260
                            ? (speed < 0 ? 1 : 0)
                            : (_rotation.value >= .42 ? 1 : 0),
                      );
                    },
              onHorizontalDragCancel: () =>
                  _settle(_rotation.value >= .42 ? 1 : 0),
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _rotation,
                  builder: (context, _) => _VehicleHeroFrame(
                    scene: scene,
                    loading: widget.loading,
                    layout: layout,
                    orbit: orbit,
                    position: _rotation.value,
                    hasRear: hasRear,
                    stageWidth: constraints.maxWidth,
                    poses: poses,
                    cards: cards,
                    colors: colors,
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

class _VehicleHeroFrame extends StatelessWidget {
  const _VehicleHeroFrame({
    required this.scene,
    required this.loading,
    required this.layout,
    required this.orbit,
    required this.position,
    required this.hasRear,
    required this.stageWidth,
    required this.poses,
    required this.cards,
    required this.colors,
  });

  final VehicleHeroScene? scene;
  final bool loading;
  final VehicleHeroLayout layout;
  final VehicleHeroOrbit? orbit;
  final double position;
  final bool hasRear;
  final double stageWidth;
  final List<VehicleHeroCardPose> poses;
  final List<Widget> cards;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final camera = orbit?.cameraAt(position);
    final connectors = <VehicleHeroConnector>[];
    final layers = <({double opacity, Widget child})>[];
    for (var index = 0; index < poses.length; index++) {
      final pose = poses[index].at(
        camera: camera,
        position: position,
        hasRear: hasRear,
        stageWidth: stageWidth,
      );
      final rect = pose.rect;
      final drawn = Rect.fromCenter(
        center: rect.center,
        width: rect.width * pose.scale,
        height: rect.height * pose.scale,
      );
      if (!drawn.overlaps(Rect.fromLTWH(0, 0, stageWidth, layout.height))) {
        continue;
      }
      if ((pose.origin, pose.end) case (final origin?, final end?)) {
        connectors.add(
          VehicleHeroConnector(
            origin,
            end,
            colors[index].withValues(alpha: pose.opacity),
          ),
        );
      }
      layers.add((
        opacity: pose.opacity,
        child: Positioned.fromRect(
          key: ValueKey(index),
          rect: rect,
          child: IgnorePointer(
            ignoring: pose.opacity < .65,
            child: ExcludeSemantics(
              excluding: pose.opacity < .65,
              child: Opacity(
                opacity: pose.opacity,
                child: Transform.scale(scale: pose.scale, child: cards[index]),
              ),
            ),
          ),
        ),
      ));
    }
    layers.sort((a, b) => a.opacity.compareTo(b.opacity));
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: layout.viewport,
          child: IgnorePointer(
            child: scene == null || camera == null
                ? Center(
                    child: loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Vista 3D non disponibile'),
                  )
                : SceneView(
                    scene!.scene,
                    camera: camera,
                    autoTick: false,
                    pixelRatio: MediaQuery.devicePixelRatioOf(
                      context,
                    ).clamp(1.0, 1.55),
                  ),
          ),
        ),
        if (connectors.isNotEmpty)
          IgnorePointer(
            child: CustomPaint(painter: VehicleHeroConnectors(connectors)),
          ),
        for (final layer in layers) layer.child,
      ],
    );
  }
}

Color _zoneColor(BuildContext context, VehicleHeroCallout callout) {
  final kpi = callout.kpi;
  final values = kpi.components.isEmpty
      ? [kpi.percentage]
      : kpi.components
            .map((component) => component.alertPercentage)
            .whereType<double>();
  return _statusColor(context, values);
}

Color _meshColor(
  BuildContext context,
  VehicleHeroCallout callout,
  String mesh,
  Color fallback,
) {
  if (callout.kpi.group != VehicleMaintenanceGroup.gearbox) return fallback;
  final label = mesh == 'differential'
      ? VehicleMaintenanceField.differential.label
      : VehicleMaintenanceField.gearbox.label;
  final status = callout.kpi.components
      .where((component) => component.label == label)
      .firstOrNull
      ?.alertPercentage;
  return _statusColor(context, [?status]);
}

Color _statusColor(BuildContext context, Iterable<double> status) {
  if (status.any((value) => value == 0)) {
    return Theme.of(context).colorScheme.error;
  }
  if (status.any((value) => value < 20)) return const Color(0xffff963e);
  return VehicleHeroScene.clearColor;
}
