import 'package:equatable/equatable.dart';

class WorkLogReport extends Equatable {
  const WorkLogReport({
    required this.id,
    required this.description,
    this.warningLightCodes = const [],
  });

  final String id;
  final String description;
  final List<String> warningLightCodes;

  @override
  List<Object?> get props => [id, description, warningLightCodes];
}
