import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class VehicleHeroScene {
  VehicleHeroScene._(this._model) {
    scene.add(_model);
  }

  static const _asset = 'lib/assets/vehicles/automob_vehicle.glb';
  static const clearColor = Color(0xff79d5fa);
  static const _bakedAccentNodes = [
    'battery_terminal_positive',
    'oil_fill_cap',
    'oil_filter_canister',
    'timing_belt',
    'caliper_bridge_FL',
    'caliper_bridge_FR',
    'caliper_bridge_RL',
    'caliper_bridge_RR',
    'caliper_piston_FL',
    'caliper_piston_FR',
    'caliper_piston_RL',
    'caliper_piston_RR',
    'spring_coil_FL',
    'spring_coil_FR',
    'spring_coil_RL',
    'spring_coil_RR',
  ];
  final Node _model;
  late final _bounds = _model.combinedWorldBounds;
  final _anchors = <String, vm.Vector3?>{};
  final _materials = <Color, PhysicallyBasedMaterial>{};
  final _restoreMaterials = <MeshPrimitive, Material>{};
  Map<String, Color> _meshColors = const {};
  final scene = Scene()
    ..environmentIntensity = 1.35
    ..directionalLight = DirectionalLight(
      direction: vm.Vector3(-3, -5, -2),
      intensity: 2,
    );

  static Future<VehicleHeroScene> load() async {
    await Scene.initializeStaticResources();
    final template = await loadScene(_asset);
    try {
      return VehicleHeroScene._(template.clone());
    } catch (_) {
      await releaseScene(_asset);
      rethrow;
    }
  }

  void highlight(Map<String, Color> colors) => _applyColors({
    for (final node in _bakedAccentNodes) node: clearColor,
    ...colors,
  });

  void _applyColors(Map<String, Color> colors) {
    if (mapEquals(_meshColors, colors)) return;
    for (final entry in _restoreMaterials.entries) {
      entry.key.material = entry.value;
    }
    _restoreMaterials.clear();
    _meshColors = colors;
    for (final entry in colors.entries) {
      final material = _materials.putIfAbsent(entry.value, () {
        final color = entry.value;
        return PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(
            color.r * .58,
            color.g * .58,
            color.b * .58,
            1,
          )
          ..emissiveFactor = vm.Vector4(
            color.r * .1,
            color.g * .1,
            color.b * .1,
            1,
          )
          ..roughnessFactor = .57;
      });
      for (final primitive
          in _model.getChildByName(entry.key)?.mesh?.primitives ??
              const <MeshPrimitive>[]) {
        _restoreMaterials[primitive] = primitive.material;
        primitive.material = material;
      }
    }
  }

  VehicleHeroOrbit orbitFor(Size viewport) {
    final bounds = _bounds;
    final target = bounds?.center ?? vm.Vector3(0, .59, 0);
    if (bounds == null || viewport.isEmpty) {
      return VehicleHeroOrbit(target, 6.6);
    }

    // Fit the full mesh for the small orbit, keeping zoom constant while dragging.
    final corners = [
      for (final x in [bounds.min.x, bounds.max.x])
        for (final y in [bounds.min.y, bounds.max.y])
          for (final z in [bounds.min.z, bounds.max.z]) vm.Vector4(x, y, z, 1),
    ];
    var near = 1.0;
    var far = ((bounds.max - bounds.min).length * 4).clamp(7.0, 30.0);
    for (var step = 0; step < 12; step++) {
      final distance = (near + far) / 2;
      final orbit = VehicleHeroOrbit(target, distance);
      final fits = [0.0, .5, 1.0].every((position) {
        final matrix = orbit.cameraAt(position).getViewTransform(viewport);
        return corners.every((point) {
          final clip = matrix.transform(point.clone());
          return clip.w > 0 &&
              clip.x.abs() <= clip.w * .94 &&
              clip.y.abs() <= clip.w * .91;
        });
      });
      if (fits) {
        far = distance;
      } else {
        near = distance;
      }
    }
    return VehicleHeroOrbit(target, far);
  }

  vm.Vector3? anchor(String part) => _anchors.putIfAbsent(
    part,
    () =>
        _model.getChildByName('anchor_$part')?.globalTransform.getTranslation(),
  );

  Future<void> dispose() async {
    _applyColors(const {});
    scene.remove(_model);
    await releaseScene(_asset);
  }
}

class VehicleHeroOrbit {
  const VehicleHeroOrbit(this.target, this.distance);

  final vm.Vector3 target;
  final double distance;

  PerspectiveCamera cameraAt(double position) {
    final angle = .76 + position * .5;
    final direction = vm.Vector3(
      math.cos(angle),
      .28,
      math.sin(angle),
    ).normalized();
    return PerspectiveCamera(
      position: target + direction * distance,
      target: target,
      fovRadiansY: 29 * vm.degrees2Radians,
    );
  }
}
