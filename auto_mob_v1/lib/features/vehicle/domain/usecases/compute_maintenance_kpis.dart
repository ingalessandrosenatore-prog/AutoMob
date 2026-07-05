import 'package:auto_mob_v1/core/types/enum_pop_up.dart';

import '../entities/maintenance_kpi.dart';
import '../entities/vehicle.dart';

/// Calcola i KPI di manutenzione di UN veicolo a partire dai suoi dati:
/// km attuali + ultimo intervento per tipo + intervalli configurati.
/// E' logica PURA di dominio: nessuna dipendenza da DB, rete o UI -> facile da
/// testare e riusabile. Il BLoC la chiama e mette il risultato nello stato.
class ComputeMaintenanceKpis {
  List<MaintenanceKpi> call(Vehicle v) {
    // Placeholder = nessun veicolo reale -> nessun KPI da mostrare.
    if (v.isPlaceholder) return const [];

    final kmAttuali = v.kmCurrent;

    // Funzione interna: costruisce un KPI dato l'ultimo km e l'intervallo.
    MaintenanceKpi calcola(EnumPopUp tipo, int? ultimoKm, int intervallo) {
      // Se non c'e' storico (mai fatto), parto dai km attuali come base.
      final base = ultimoKm ?? kmAttuali;
      final prossimoKm = base + intervallo; // km a cui andrebbe rifatto
      final mancanti = prossimoKm - kmAttuali; // puo' essere negativo (scaduto)
      // Evito la divisione per zero se l'intervallo non e' configurato.
      final perc = intervallo <= 0
          ? 0.0
          : ((mancanti * 100) / intervallo).clamp(0.0, 100.0);
      return MaintenanceKpi(type: tipo, remainingKm: mancanti, percentage: perc);
    }

    return [
      calcola(EnumPopUp.aggiornaTagliando, v.lastTagliandoKm, v.tagliandoIntervalKm),
      // La distribuzione la mostro solo se ho un intervallo valido sul veicolo.
      if (v.distribuzioneIntervalKm != null && v.distribuzioneIntervalKm! > 0)
        calcola(EnumPopUp.aggiornaDistribuzione, v.lastDistribuzioneKm,
            v.distribuzioneIntervalKm!),
      calcola(EnumPopUp.aggiornaCambioGomme, v.lastTireChangeKm, v.tireChangeIntervalKm),
      calcola(EnumPopUp.pneumaticiInversione, v.lastTireRotationKm, v.tireRotationIntervalKm),
    ];
  }
}
