import 'package:equatable/equatable.dart';

import 'package:auto_mob_v1/core/types/enum_pop_up.dart';

/// KPI di una manutenzione "a chilometri" (tagliando, distribuzione, gomme...).
/// E' un valore CALCOLATO (non sta sul DB): dice quanti km mancano al prossimo
/// intervento e la percentuale di "vita" residua rispetto all'intervallo.
class MaintenanceKpi extends Equatable {
  /// Di che manutenzione si tratta (riusa l'enum condiviso in core/types).
  final EnumPopUp type;

  /// Km mancanti al prossimo intervento. Negativo = gia' scaduto.
  final int remainingKm;

  /// 0..100: quanto manca, in percentuale, rispetto all'intervallo.
  final double percentage;

  const MaintenanceKpi({
    required this.type,
    required this.remainingKm,
    required this.percentage,
  });

  @override
  List<Object?> get props => [type, remainingKm, percentage];
}
