import 'package:equatable/equatable.dart';

import 'work_log_entry.dart';

/// Contesto tipizzato per aprire un dettaglio anche da superfici esterne allo
/// storico, senza esporre router o dipendenze applicative al package.
class WorkLogDetailLaunch extends Equatable {
  const WorkLogDetailLaunch({
    required this.entry,
    required this.currentKm,
    required this.vehicleName,
  });

  final WorkLogEntry entry;
  final int currentKm;
  final String vehicleName;

  Map<String, Object> toRouteExtra() => {
    'workLogEntry': entry,
    'currentKm': currentKm,
    'vehicleName': vehicleName,
  };

  static WorkLogDetailLaunch? tryFromRouteExtra(Object? value) {
    if (value is WorkLogDetailLaunch) return value;
    if (value is! Map) return null;
    final entry = value['workLogEntry'];
    final currentKm = value['currentKm'];
    final vehicleName = value['vehicleName'];
    if (entry is! WorkLogEntry || currentKm is! int || vehicleName is! String) {
      return null;
    }
    return WorkLogDetailLaunch(
      entry: entry,
      currentKm: currentKm,
      vehicleName: vehicleName,
    );
  }

  @override
  List<Object?> get props => [entry, currentKm, vehicleName];
}
