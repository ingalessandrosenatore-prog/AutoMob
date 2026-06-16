import 'package:equatable/equatable.dart';

import '../../domain/entiti/VehicleOption.dart';
import '../../domain/entiti/WorkLogRow.dart';

/// Stato globale della pagina (il "primo caricamento"):
/// - initial: appena creato;
/// - loading: sto caricando veicoli + prima pagina (pop-up spinner);
/// - loaded: pagina pronta (anche se 0 veicoli o 0 lavori);
/// - error: caricamento fallito (pop-up errore).
enum HistoryStatus { initial, loading, loaded, error }

class WorkLogHistoryState extends Equatable {
  final HistoryStatus status;
  final List<VehicleOption> vehicles;
  final String? selectedVehicleId;
  final List<WorkLogRow> works;

  /// true mentre carico la fetta successiva (spinner in fondo alla lista).
  final bool isLoadingMore;

  /// true quando l'ultima fetta ha reso < pageSize: non ci sono altri lavori.
  final bool hasReachedMax;

  final String? errorMessage;

  const WorkLogHistoryState({
    this.status = HistoryStatus.initial,
    this.vehicles = const [],
    this.selectedVehicleId,
    this.works = const [],
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  factory WorkLogHistoryState.initial() => const WorkLogHistoryState();

  WorkLogHistoryState copyWith({
    HistoryStatus? status,
    List<VehicleOption>? vehicles,
    String? selectedVehicleId,
    List<WorkLogRow>? works,
    bool? isLoadingMore,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return WorkLogHistoryState(
      status: status ?? this.status,
      vehicles: vehicles ?? this.vehicles,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      works: works ?? this.works,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        vehicles,
        selectedVehicleId,
        works,
        isLoadingMore,
        hasReachedMax,
        errorMessage,
      ];
}
