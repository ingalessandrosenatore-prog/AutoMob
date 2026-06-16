import 'package:equatable/equatable.dart';

sealed class WorkLogHistoryEvent extends Equatable {
  const WorkLogHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Avvio pagina: carico i veicoli e i lavori del primo veicolo (pagina 0).
class LoadInitial extends WorkLogHistoryEvent {
  const LoadInitial();
}

/// Cambio veicolo dal dropdown: resetto la lista e ricarico dalla pagina 0.
class VehicleChanged extends WorkLogHistoryEvent {
  final String vehicleId;
  const VehicleChanged(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

/// Arrivati in fondo allo scroll: carico la prossima fetta di lavori.
class LoadMore extends WorkLogHistoryEvent {
  const LoadMore();
}

/// Riprova dopo un errore (dal pop-up): rilancia il caricamento iniziale.
class Retry extends WorkLogHistoryEvent {
  const Retry();
}

/// Ricarica i lavori del veicolo gia' selezionato (es. al ritorno
/// dall'aggiunta di un lavoro), senza perdere la selezione.
class ReloadCurrent extends WorkLogHistoryEvent {
  const ReloadCurrent();
}
