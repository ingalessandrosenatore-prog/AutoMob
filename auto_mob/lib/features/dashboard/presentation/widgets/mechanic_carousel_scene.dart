import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'mechanic_3d_configuration.dart';
import 'mechanic_actor.dart';
import 'mechanic_carousel_layout.dart';
import 'mechanic_model_cache.dart';

/// @brief Un'unica scena, con un nodo figlio per ciascun meccanico.
class MechanicCarouselScene {
  MechanicCarouselScene._(
    this.assetPath,
    this.actors, {
    required this.ownsTemplate,
  }) {
    for (final actor in actors) {
      scene.add(actor.node);
    }
  }
  final String assetPath;
  final bool ownsTemplate;
  final List<MechanicActor> actors;
  final Scene scene = Scene();
  final camera = PerspectiveCamera(
    position: vm.Vector3(0, 2.6, -9),
    target: vm.Vector3(0, 2.5, 0),
  );
  int? _active;

  static Future<MechanicCarouselScene> load(
    String assetPath,
    List<Mechanic3dConfiguration> configurations, {
    MechanicModelCache? models,
  }) async {
    if (models == null) await Scene.initializeStaticResources();
    final template = await (models?.load() ?? loadScene(assetPath));
    try {
      return MechanicCarouselScene._(assetPath, [
        for (final configuration in configurations)
          MechanicActor(template, configuration),
      ], ownsTemplate: models == null);
    } catch (_) {
      if (models == null) await releaseScene(assetPath);
      rethrow;
    }
  }

  /// @brief Sposta i figli senza ricaricare GLB o ricostruire la scena.
  void arrange(double position, double aspectRatio) {
    for (var i = 0; i < actors.length; i++) {
      final distance = i + 1 - position;
      final place = MechanicCarouselLayout.at(distance);
      // Compensate perspective so horizontal slots follow the widget's width.
      final width = 2 * math.tan(math.pi / 8) * (9 + place.depth) * aspectRatio;
      final node = actors[i].node;
      node.visible = place.opacity > .01;
      // Il modello sale nello spazio 3D, non con un Transform sul viewport:
      // così scena e label restano allineate mentre il carosello si riduce.
      node.position = vm.Vector3(
        place.x * width,
        (1 - place.scale) * 1.8 + 1.3,
        place.depth,
      );
      node.scale = vm.Vector3.all(place.scale * .88);
      node.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        distance.clamp(-1, 1) * .12,
      );
    }
  }

  /// @brief Avvia una sola animazione, soltanto dopo l'arrivo nello slot 1.
  /// @param index Indice dell'omino; null sospende tutti durante il trascinamento.
  void select(int? index) {
    if (_active == index) return;
    if (index != null && (index < 0 || index >= actors.length)) return;
    if (_active case final previous?) actors[previous].freeze();
    _active = index;
    if (index != null && index < actors.length) actors[index].activate();
  }

  void tick(double deltaSeconds) {
    // SceneView recreates its ticker after autoTick resumes, but retains the
    // previous elapsed time. Ignore that reset and avoid catching up a pause.
    if (!deltaSeconds.isFinite || deltaSeconds <= 0) return;
    if (_active case final index?) {
      actors[index].tick(deltaSeconds.clamp(0, 1 / 15));
    }
  }

  Future<void> release() async {
    for (final actor in actors) {
      actor.freeze();
      scene.remove(actor.node);
    }
    if (ownsTemplate) await releaseScene(assetPath);
  }
}
