import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'vehicle_hero_connectors.dart';

class VehicleHeroCardPose {
  VehicleHeroCardPose({
    required this.rest,
    required Rect? rearRest,
    required this.viewport,
    required this.rear,
    required this.keepsFocus,
    required this.backgroundOpacity,
    required this.anchor,
    required PerspectiveCamera? frontCamera,
    required PerspectiveCamera? rearCamera,
    this.wireEdge = VehicleHeroWireEdge.nearest,
  }) : _frontPoint = _atAnchorDepth(rest.center, viewport, anchor, frontCamera),
       _rearPoint = rearRest == null
           ? null
           : _atAnchorDepth(rearRest.center, viewport, anchor, rearCamera),
       _frontDepth = anchor == null || frontCamera == null
           ? null
           : (anchor - frontCamera.position).dot(frontCamera.forward),
       _wireLimit = wireEdge == VehicleHeroWireEdge.nearest
           ? null
           : _initialWireLength(
               rear
                   ? Rect.fromCenter(
                       center: rest.center,
                       width: rest.width * .86,
                       height: rest.height * .86,
                     )
                   : rest,
               viewport,
               anchor,
               frontCamera,
               wireEdge,
             );

  final Rect rest;
  final Rect viewport;
  final bool rear;
  final bool keepsFocus;
  final double backgroundOpacity;
  final vm.Vector3? anchor;
  final VehicleHeroWireEdge wireEdge;
  final vm.Vector3? _frontPoint;
  final vm.Vector3? _rearPoint;
  final double? _frontDepth;
  final double? _wireLimit;

  static vm.Vector3? _atAnchorDepth(
    Offset preferred,
    Rect viewport,
    vm.Vector3? anchor,
    PerspectiveCamera? camera,
  ) {
    if (anchor == null || camera == null || viewport.isEmpty) return null;
    final ray = camera.screenPointToRay(
      preferred - viewport.topLeft,
      viewport.size,
    );
    final direction = camera.forward;
    final scale =
        (anchor - ray.origin).dot(direction) / ray.direction.dot(direction);
    return ray.origin + ray.direction * scale;
  }

  static double? _initialWireLength(
    Rect rest,
    Rect viewport,
    vm.Vector3? anchor,
    PerspectiveCamera? frontCamera,
    VehicleHeroWireEdge edge,
  ) {
    if (anchor == null || frontCamera == null || viewport.isEmpty) return null;
    final point = frontCamera.worldToScreen(anchor, viewport.size);
    if (point == null) return null;
    final origin = point + viewport.topLeft;
    return VehicleHeroConnector.length(origin, edge.on(rest, origin));
  }

  ({Rect rect, double opacity, double scale, Offset? origin, Offset? end}) at({
    required PerspectiveCamera? camera,
    required double position,
    required bool hasRear,
    required double stageWidth,
  }) {
    final front = _frontPoint;
    final joint = anchor;
    if (camera == null || front == null || joint == null) {
      return (rect: rest, opacity: 1, scale: 1, origin: null, end: null);
    }

    final point = _rearPoint == null
        ? front
        : front + (_rearPoint - front) * position;
    final localCenter = camera.worldToScreen(point, viewport.size);
    final localOrigin = camera.worldToScreen(joint, viewport.size);
    final origin = localOrigin == null ? null : localOrigin + viewport.topLeft;
    final amount = !hasRear || keepsFocus
        ? 1.0
        : rear
        ? position
        : (1 - position / .83).clamp(0.0, 1.0);
    final focus = amount * amount * (3 - 2 * amount);
    final direction = rest.center.dx > stageWidth / 2 ? 1 : -1;
    final retreat = !hasRear || keepsFocus || rear ? 0.0 : position;
    final offset = Offset(direction * retreat * stageWidth * .34, 0);
    final viewDepth = (joint - camera.position).dot(camera.forward);
    final depthScale = (_frontDepth! / viewDepth).clamp(.88, 1.1);
    final scale = (rear ? .86 + focus * .14 : .66 + focus * .34) * depthScale;
    final center =
        (localCenter == null ? rest.center : localCenter + viewport.topLeft) +
        offset;
    var rect = Rect.fromCenter(
      center: center,
      width: rest.width,
      height: rest.height,
    );
    Offset? end;
    if (origin != null) {
      final visibleCard = Rect.fromCenter(
        center: center,
        width: rest.width * scale,
        height: rest.height * scale,
      );
      final desired = wireEdge.on(visibleCard, origin);
      final limit = _wireLimit;
      end = limit == null
          ? desired
          : VehicleHeroConnector.limitedEnd(origin, desired, limit);
      final shift = end - desired;
      rect = rect.shift(shift);
    }
    return (
      rect: rect,
      scale: scale,
      opacity: backgroundOpacity + focus * (1 - backgroundOpacity),
      origin: origin,
      end: end,
    );
  }
}
