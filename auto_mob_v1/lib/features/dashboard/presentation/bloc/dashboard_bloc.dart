import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/domain/usecases/compute_maintenance_kpis.dart';
import '../../../vehicle/domain/usecases/get_vehicles.dart';
import '../../../vehicle/domain/usecases/update_vehicle_photo.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetVehicles getVehicles;
  final ComputeMaintenanceKpis computeKpis;
  final UpdateVehiclePhoto updateVehiclePhoto;

  DashboardBloc({
    required this.getVehicles,
    required this.computeKpis,
    required this.updateVehiclePhoto,
  }) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<DashboardPageChanged>(_onVehicleChange);
    on<VehiclePhotoUpdateRequested>(_onVehiclePhotoUpdateRequested);
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

  Future<void> _onVehiclePhotoUpdateRequested(
    VehiclePhotoUpdateRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final result = await updateVehiclePhoto(
      targa: event.targa,
      foto: event.foto,
    );
    await result.fold(
      (failure) async {},
      (_) => _onLoadDashboardData(LoadDashboardData(), emit),
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
