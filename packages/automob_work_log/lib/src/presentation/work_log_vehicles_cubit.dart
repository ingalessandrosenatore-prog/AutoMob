import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/work_log_use_cases.dart';
import '../domain/work_log_vehicle.dart';

sealed class WorkLogVehiclesState {
  const WorkLogVehiclesState();
}

class WorkLogVehiclesLoading extends WorkLogVehiclesState {
  const WorkLogVehiclesLoading();
}

class WorkLogVehiclesLoaded extends WorkLogVehiclesState {
  const WorkLogVehiclesLoaded({
    required this.vehicles,
    required this.selectedVehicleId,
  });

  final List<WorkLogVehicle> vehicles;
  final String? selectedVehicleId;

  WorkLogVehicle? get selectedVehicle {
    for (final vehicle in vehicles) {
      if (vehicle.id == selectedVehicleId) return vehicle;
    }
    return null;
  }
}

class WorkLogVehiclesFailure extends WorkLogVehiclesState {
  const WorkLogVehiclesFailure(this.message);

  final String message;
}

/// Gestisce caricamento e selezione del veicolo senza conoscere la AppBar
/// concreta delle due applicazioni.
class WorkLogVehiclesCubit extends Cubit<WorkLogVehiclesState> {
  WorkLogVehiclesCubit({required this.getWorkLogVehicles})
    : super(const WorkLogVehiclesLoading());

  final GetWorkLogVehicles getWorkLogVehicles;

  Future<void> load({String? initialVehicleId}) async {
    final previousId = switch (state) {
      WorkLogVehiclesLoaded(:final selectedVehicleId) => selectedVehicleId,
      _ => null,
    };
    emit(const WorkLogVehiclesLoading());
    final result = await getWorkLogVehicles();
    result.fold((message) => emit(WorkLogVehiclesFailure(message)), (vehicles) {
      final requestedId = initialVehicleId ?? previousId;
      final selectedId = vehicles.any((vehicle) => vehicle.id == requestedId)
          ? requestedId
          : vehicles.firstOrNull?.id;
      emit(
        WorkLogVehiclesLoaded(
          vehicles: vehicles,
          selectedVehicleId: selectedId,
        ),
      );
    });
  }

  void seed(WorkLogVehicle vehicle) => emit(
    WorkLogVehiclesLoaded(vehicles: [vehicle], selectedVehicleId: vehicle.id),
  );

  void updateCurrentKm(String vehicleId, int currentKm) {
    final current = state;
    if (current is! WorkLogVehiclesLoaded) return;
    emit(
      WorkLogVehiclesLoaded(
        vehicles: current.vehicles
            .map(
              (vehicle) => vehicle.id == vehicleId
                  ? WorkLogVehicle(
                      id: vehicle.id,
                      name: vehicle.name,
                      plate: vehicle.plate,
                      currentKm: currentKm,
                    )
                  : vehicle,
            )
            .toList(growable: false),
        selectedVehicleId: current.selectedVehicleId,
      ),
    );
  }

  void select(String vehicleId) {
    final current = state;
    if (current is! WorkLogVehiclesLoaded ||
        current.selectedVehicleId == vehicleId ||
        !current.vehicles.any((vehicle) => vehicle.id == vehicleId)) {
      return;
    }
    emit(
      WorkLogVehiclesLoaded(
        vehicles: current.vehicles,
        selectedVehicleId: vehicleId,
      ),
    );
  }
}
