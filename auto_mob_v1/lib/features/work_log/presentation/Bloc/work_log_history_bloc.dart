import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecase/GetVehicleOptions.dart';
import '../../domain/usecase/GetVehicleWorks.dart';
import 'work_log_history_event.dart';
import 'work_log_history_state.dart';

/// Bloc dello storico lavori. Responsabilita': caricare i veicoli, i lavori
/// del veicolo selezionato e paginarli. Separato dal WorkLogBloc (creazione).
class WorkLogHistoryBloc
    extends Bloc<WorkLogHistoryEvent, WorkLogHistoryState> {
  final GetVehicleOptions getVehicleOptions;
  final GetVehicleWorks getVehicleWorks;

  /// Quanti lavori carico per fetta. Una fetta piu' corta = sono finiti.
  static const int pageSize = 20;

  WorkLogHistoryBloc({
    required this.getVehicleOptions,
    required this.getVehicleWorks,
  }) : super(WorkLogHistoryState.initial()) {
    on<LoadInitial>((_, emit) => _loadInitial(emit));
    on<Retry>((_, emit) => _loadInitial(emit));
    on<VehicleChanged>(_onVehicleChanged);
    on<ReloadCurrent>(_onReloadCurrent);
    // droppable: mentre una LoadMore e' in corso, le altre vengono scartate.
    on<LoadMore>(_onLoadMore, transformer: droppable());
  }

  /// Ricarica la pagina 0 del veicolo gia' selezionato (refresh dopo aggiunta).
  Future<void> _onReloadCurrent(
    ReloadCurrent event,
    Emitter<WorkLogHistoryState> emit,
  ) async {
    final id = state.selectedVehicleId;
    if (id == null) return;

    emit(state.copyWith(works: const [], isLoadingMore: true, hasReachedMax: false));

    final res = await getVehicleWorks(vehicleId: id, from: 0, to: pageSize - 1);
    res.fold(
      (f) => emit(state.copyWith(isLoadingMore: false)),
      (works) => emit(state.copyWith(
        works: works,
        isLoadingMore: false,
        hasReachedMax: works.length < pageSize,
      )),
    );
  }

  /// Primo caricamento (e Retry): veicoli + prima pagina del primo veicolo.
  Future<void> _loadInitial(Emitter<WorkLogHistoryState> emit) async {
    emit(state.copyWith(status: HistoryStatus.loading, errorMessage: null));

    final vehiclesRes = await getVehicleOptions();
    final vehicles = vehiclesRes.getOrElse((_) => []);

    if (vehiclesRes.isLeft()) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: _msg(vehiclesRes),
      ));
      return;
    }

    // Nessun veicolo: pagina "pronta" ma vuota -> il pop-up warning lo decide
    // la UI guardando vehicles.isEmpty.
    if (vehicles.isEmpty) {
      emit(state.copyWith(
        status: HistoryStatus.loaded,
        vehicles: vehicles,
        works: const [],
        hasReachedMax: true,
      ));
      return;
    }

    final firstId = vehicles.first.id;
    final worksRes = await getVehicleWorks(vehicleId: firstId, from: 0, to: pageSize - 1);

    worksRes.fold(
      (f) => emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: f.message,
      )),
      (works) => emit(state.copyWith(
        status: HistoryStatus.loaded,
        vehicles: vehicles,
        selectedVehicleId: firstId,
        works: works,
        isLoadingMore: false,
        hasReachedMax: works.length < pageSize,
      )),
    );
  }

  /// Cambio veicolo: NON ripropongo il pop-up a tutto schermo. Svuoto la lista,
  /// mostro uno spinner inline (isLoadingMore) e ricarico dalla pagina 0.
  Future<void> _onVehicleChanged(
    VehicleChanged event,
    Emitter<WorkLogHistoryState> emit,
  ) async {
    if (event.vehicleId == state.selectedVehicleId) return;

    emit(state.copyWith(
      selectedVehicleId: event.vehicleId,
      works: const [],
      isLoadingMore: true,
      hasReachedMax: false,
    ));

    final res = await getVehicleWorks(
      vehicleId: event.vehicleId,
      from: 0,
      to: pageSize - 1,
    );

    res.fold(
      (f) => emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: f.message,
        isLoadingMore: false,
      )),
      (works) => emit(state.copyWith(
        works: works,
        isLoadingMore: false,
        hasReachedMax: works.length < pageSize,
      )),
    );
  }

  /// Carica la fetta successiva. Guardie: non sto gia' caricando, non ho gia'
  /// finito, ho un veicolo selezionato. L'offset = quanti lavori ho gia'.
  Future<void> _onLoadMore(
    LoadMore event,
    Emitter<WorkLogHistoryState> emit,
  ) async {
    if (state.isLoadingMore ||
        state.hasReachedMax ||
        state.selectedVehicleId == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    final from = state.works.length;
    final res = await getVehicleWorks(
      vehicleId: state.selectedVehicleId!,
      from: from,
      to: from + pageSize - 1,
    );

    res.fold(
      // Errore in coda: non butto giu' la lista con un pop-up, spengo solo
      // lo spinner. L'utente puo' riprovare scrollando di nuovo.
      (f) => emit(state.copyWith(isLoadingMore: false)),
      (nuovi) => emit(state.copyWith(
        works: [...state.works, ...nuovi],
        isLoadingMore: false,
        hasReachedMax: nuovi.length < pageSize,
      )),
    );
  }

  String _msg(dynamic either) =>
      either.fold((f) => f.message as String, (_) => '');
}
