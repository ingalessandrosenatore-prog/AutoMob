import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/domain/usecases/GetVehicles.dart';
import 'dashboardEvent.dart';
import 'dashboardState.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetVehicles getVehicles;

  DashboardBloc({required this.getVehicles}) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    // Per ora carichiamo solo i veicoli. In futuro qui aggiungeremo
    // gli altri use case (KPI, scadenze, alert) e popoleremo DashboardLoaded.
    final result = await getVehicles();
    result.fold(
      (failure) => emit(DashboardError(message: failure.message)),
      (vehicles) {
        // Lista vuota: mostriamo comunque qualcosa con un veicolo placeholder.
        if (vehicles.isEmpty) {
          emit(DashboardLoaded(vehicles: [Vehicle.placeholder()]));
        } else {
          emit(DashboardLoaded(vehicles: vehicles));
        }
      },
    );
  }
}
