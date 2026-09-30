import 'package:equatable/equatable.dart';

/// Aspetto assegnato a un'officina per la durata della sessione dell'app.
class WorkshopMascot extends Equatable {
  const WorkshopMascot({
    required this.mechanicId,
    required this.pose,
    required this.prop,
    required this.baseColor,
    required this.accentColor,
  });

  final String mechanicId;
  final String pose;
  final String prop;
  final String baseColor;
  final String accentColor;

  @override
  List<Object?> get props => [mechanicId, pose, prop, baseColor, accentColor];
}
