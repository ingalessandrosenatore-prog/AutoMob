import 'package:equatable/equatable.dart';

/// @brief Aspetto immutabile di un omino del carosello.
/// @details Non contiene oggetti GPU: descrive soltanto posa, attrezzo e colori.
/// La configurazione viene scelta una volta, non a ogni build del widget.
class Mechanic3dConfiguration extends Equatable {
  const Mechanic3dConfiguration({
    required this.id,
    required this.name,
    this.pose = 'standing',
    this.tool = 'wrench',
    this.baseColor = 0xFF252930,
    this.accentColor = 0xFFFF7926,
  }) : assert(pose == 'standing' || pose == 'desk'),
       assert(
         tool == 'wrench' ||
             tool == 'screwdriver' ||
             tool == 'tablet' ||
             tool == 'tire',
       ),
       assert(pose != 'desk' || tool != 'tire');

  final String id;
  final String name;
  final String pose;
  final String tool;
  final int baseColor;
  final int accentColor;

  @override
  List<Object> get props => [id, name, pose, tool, baseColor, accentColor];

  String get idleClip => '${pose}_${tool}_idle';
  String get actionClip =>
      '${pose}_${tool}_${switch (tool) {
        'tablet' => 'tap',
        'tire' => 'dribble',
        _ => 'spin',
      }}';
}
