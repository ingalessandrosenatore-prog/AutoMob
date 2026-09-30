import 'package:auto_mob_v1/core/types/enum_pop_up.dart';

import '../entities/maintenance_kpi.dart';
import '../entities/maintenance_defaults.dart';
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
      // Un lavoro sconosciuto parte da zero: la base deve restare stabile anche
      // quando aumentano i km correnti del veicolo.
      final base = ultimoKm ?? MaintenanceDefaults.initialKm;
      if (intervallo == 0) {
        switch (tipo) {
          case EnumPopUp.aggiornaTagliando:
            intervallo = MaintenanceDefaults.tagliandoIntervalKm;
          case EnumPopUp.aggiornaDistribuzione:
            intervallo = MaintenanceDefaults.distribuzioneIntervalKm;
          case EnumPopUp.aggiornaCambioGomme:
            intervallo = MaintenanceDefaults.tireChangeIntervalKm;
          case EnumPopUp.revisione:
            throw UnimplementedError();
          case EnumPopUp.pneumaticiInversione:
            intervallo = MaintenanceDefaults.tireRotationIntervalKm;
          case EnumPopUp.altro:
            throw UnimplementedError();
        }
      }
      final prossimoKm = base + intervallo; // km a cui andrebbe rifatto
      final mancanti = prossimoKm - kmAttuali; // puo' essere negativo (scaduto)
      // Evito la divisione per zero se l'intervallo non e' configurato.
      final perc = intervallo <= 0
          ? 0.0
          : ((mancanti * 100) / intervallo).clamp(0.0, 100.0);
      return MaintenanceKpi(
        type: tipo,
        remainingKm: mancanti,
        percentage: perc,
      );
    }

    return [
      calcola(
        EnumPopUp.aggiornaTagliando,
        v.lastTagliandoKm,
        v.tagliandoIntervalKm,
      ),
      calcola(
        EnumPopUp.aggiornaDistribuzione,
        v.lastDistribuzioneKm,
        v.distribuzioneIntervalKm ??
            MaintenanceDefaults.distribuzioneIntervalKm,
      ),
      calcola(
        EnumPopUp.aggiornaCambioGomme,
        v.lastTireChangeKm,
        v.tireChangeIntervalKm,
      ),
      calcola(
        EnumPopUp.pneumaticiInversione,
        v.lastTireRotationKm,
        v.tireRotationIntervalKm,
      ),
    ];
  }
}
