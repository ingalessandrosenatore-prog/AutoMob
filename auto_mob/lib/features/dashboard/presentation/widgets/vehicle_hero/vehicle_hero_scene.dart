import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class VehicleHeroScene {
  VehicleHeroScene._(Node model)
    : _model = model,
      _wheels = [
        for (final corner in ['FL', 'FR', 'RL', 'RR'])
          for (final part in ['tire', 'rim'])
            if (model.getChildByName('${part}_$corner') case final node?)
              (node: node, original: node.rotation),
      ] {
    final accent = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(.46, .16, .059, 1)
      ..emissiveFactor = vm.Vector4(.064, .022, .008, 1)
      ..roughnessFactor = .57;
    for (final name in [
      'tire_FL',
      'oil_pan',
      'timing_belt',
      'timing_sprocket_1',
      'timing_sprocket_2',
      'timing_sprocket_3',
    ]) {
      for (final primitive
          in model.getChildByName(name)?.mesh?.primitives ??
              const <MeshPrimitive>[]) {
        primitive.material = accent;
      }
    }
    scene.add(model);
  }

  static const _asset = 'lib/assets/vehicles/automob_vehicle.glb';
  static const _driveDistance = 5.6;
  static const _tireRadius = .329;
  final Node _model;
  final List<({Node node, vm.Quaternion original})> _wheels;
  final scene = Scene()
    ..environmentIntensity = 1.35
    ..directionalLight = DirectionalLight(
      direction: vm.Vector3(-3, -5, -2),
      intensity: 2,
    );

  // Scene mirrors glTF's Z axis. This eye sees the flank on the right of
  // the reference image, with the nose at the lower left.
  final camera = PerspectiveCamera(
    position: vm.Vector3(4.45, 1.75, 3.8),
    target: vm.Vector3(1.00, .63, .10),
    fovRadiansY: 31 * vm.degrees2Radians,
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

  void drive(double progress) {
    final remaining = _driveDistance * (1 - progress);
    _model.position = vm.Vector3(-remaining, 0, 0);
    final roll = vm.Quaternion.axisAngle(
      vm.Vector3(0, 0, 1),
      remaining / _tireRadius,
    );
    for (final (:node, :original) in _wheels) {
      node.rotation = roll * original;
    }
  }

  vm.Vector3 anchor(String part) {
    final node = _model.getChildByName('anchor_$part');
    if (node == null) throw StateError('Vehicle anchor missing: $part');
    // Callouts lay out at their parked positions while the model is moving.
    return node.globalTransform.getTranslation() - _model.position;
  }

  Future<void> dispose() async {
    scene.remove(_model);
    await releaseScene(_asset);
  }
}
