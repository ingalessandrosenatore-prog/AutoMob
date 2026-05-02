import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/domain/usecases/GetVehicles.dart';
import 'dashboardEvent.dart';
import 'dashboardState.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetVehicles getVehicles;

  DashboardBloc({required this.getVehicles}) : super(DashboardInitial()) {
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
        if (vehicles.isEmpty) {
          // Lista vuota: mostriamo il placeholder
          emit(DashboardLoaded(vehicles: [Vehicle.placeholder()], index: 0));
        } else {
          // Lista non vuota
          emit(DashboardLoaded(vehicles: vehicles, index: 0));
        }
      },
    );
  }





  FutureOr<void> _onVehicleChange(DashboardPageChanged event, Emitter<DashboardState> emit) {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      emit(currentState.copyWith(index: event.newIndex));
    }
  }
}
