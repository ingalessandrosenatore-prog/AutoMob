import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/domain/usecases/ComputeMaintenanceKpis.dart';
import '../../../vehicle/domain/usecases/GetVehicles.dart';
import 'dashboardEvent.dart';
import 'dashboardState.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetVehicles getVehicles;
  final ComputeMaintenanceKpis computeKpis;

  DashboardBloc({
    required this.getVehicles,
    required this.computeKpis,
  }) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<DashboardPageChanged>(_onVehicleChange);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    final result = await getVehicles();
    result.fold(
      (failure) => emit(DashboardError(message: failure.message)),
      (vehicles) {
        // Lista vuota -> mostro un placeholder cosi' la UI ha sempre qualcosa.
        final lista = vehicles.isEmpty ? [Vehicle.placeholder()] : vehicles;
        emit(DashboardLoaded(
          vehicles: lista,
          index: 0,
          // KPI del primo veicolo (il placeholder restituisce lista vuota).
          kpis: computeKpis(lista.first),
        ));
      },
    );
  }

  FutureOr<void> _onVehicleChange(
    DashboardPageChanged event,
    Emitter<DashboardState> emit,
  ) {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final veicoloSelezionato = currentState.vehicles[event.newIndex];
      // Cambiando veicolo ricalcolo i suoi KPI.
      emit(currentState.copyWith(
        index: event.newIndex,
        kpis: computeKpis(veicoloSelezionato),
      ));
    }
  }
}
