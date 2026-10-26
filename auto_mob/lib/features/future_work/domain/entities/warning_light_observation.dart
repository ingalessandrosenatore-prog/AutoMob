import 'package:equatable/equatable.dart';

class WarningLightObservation extends Equatable {
  const WarningLightObservation({
    required this.code,
    required this.color,
    this.flashing = false,
  });
  final String code;
  final String color;
  final bool flashing;
  @override
  List<Object> get props => [code, color, flashing];
}
