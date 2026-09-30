import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'mechanic_3d_configuration.dart';

/// Un omino: nodo indipendente, materiali dei vestiti e una sola clip attiva.
class MechanicActor {
  MechanicActor(Node template, this.configuration) : model = template.clone() {
    node.add(model);
    for (final clip in [configuration.idleClip, configuration.actionClip]) {
      if (model.findAnimationByName(clip) == null) {
        throw StateError('Clip assente nel GLB: $clip');
      }
    }
    for (final pose in ['standing', 'desk']) {
      model.getChildByName('AM_${pose.toUpperCase()}')!.visible =
          pose == configuration.pose;
      for (final tool in ['wrench', 'screwdriver', 'tablet', 'tire']) {
        model.getChildByName('${pose}_PROP_$tool')?.visible =
            tool == configuration.tool;
      }
    }
    // Il banco è indipendente dal personaggio: ridurne la larghezza qui
    // evita di deformare viso, mani e vestiti della posa seduta.
    model.getChildByName('desk_WORKBENCH')?.scale = vm.Vector3(.60, 1, 1);
    _setClothesColors();
    // I due scheletri del GLB hanno nomi di ossa uguali: il binding deve
    // cercare soltanto nella posa scelta, mai nell'intero modello.
    _rig = model.getChildByName('AM_${configuration.pose.toUpperCase()}')!;
    _play(configuration.idleClip, loop: true, playing: false);
  }

  final Mechanic3dConfiguration configuration;
  final Node node = Node();
  final Node model;
  AnimationClip? _clip;
  late final Node _rig;
  final AnimationPlayer _player = AnimationPlayer();
  bool _active = false;
  bool _showingAction = false;

  bool get isAnimating => _clip?.playing ?? false;

  void activate() {
    _active = true;
    _showingAction = true;
    _play(configuration.actionClip, loop: false);
  }

  void freeze() {
    _active = false;
    // La clip ferma al fotogramma iniziale mantiene la presa corretta dell'attrezzo.
    // Il tempo non avanza: soltanto il personaggio selezionato viene animato.
    _play(configuration.idleClip, loop: true, playing: false);
  }

  void tick(double deltaSeconds) {
    if (!_active) return;
    _player.update(deltaSeconds);
    if (_active && _showingAction && _clip?.playing == false) {
      _showingAction = false;
      _play(configuration.idleClip, loop: true);
    }
  }

  void _play(String name, {required bool loop, bool playing = true}) {
    if (_clip case final clip?) _player.removeClip(clip);
    final animation = model.findAnimationByName(name);
    if (animation == null) throw StateError('Clip assente nel GLB: $name');
    _clip = _player.createAnimationClip(animation, _rig)..loop = loop;
    // Applica subito la presa iniziale. Il player è aggiornato manualmente
    // solo per il selezionato: gli altri conservano la posa senza ricalcolarla.
    _player.update(0);
    if (playing) _clip!.play();
  }

  void _setClothesColors() {
    // Only clothing materials are per-instance; geometry and other materials
    // stay shared. Changing one mechanic must never recolor all the others.
    final replacements = <String, PhysicallyBasedMaterial>{};
    for (final part in model.meshNodes) {
      for (final primitive in part.mesh!.primitives) {
        final original = primitive.material;
        final color = switch (original.name) {
          'AM_Clothes_Base' => configuration.baseColor,
          'AM_Clothes_Accent' => configuration.accentColor,
          _ => null,
        };
        if (color == null || original is! PhysicallyBasedMaterial) continue;
        primitive.material = replacements.putIfAbsent(
          original.name,
          () => PhysicallyBasedMaterial()
            ..name = original.name
            ..baseColorFactor = _linearColor(color)
            ..roughnessFactor = original.roughnessFactor
            ..metallicFactor = original.metallicFactor,
        );
      }
    }
  }

  vm.Vector4 _linearColor(int argb) {
    double channel(int value) {
      final c = value / 255;
      return c <= .04045
          ? c / 12.92
          : math.pow((c + .055) / 1.055, 2.4).toDouble();
    }

    return vm.Vector4(
      channel((argb >> 16) & 255),
      channel((argb >> 8) & 255),
      channel(argb & 255),
      1,
    );
  }
}
