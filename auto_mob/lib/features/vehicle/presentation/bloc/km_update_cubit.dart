import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/update_vehicle_km.dart';
import '../../domain/usecases/add_fuel_expense.dart';
import '../../domain/entities/fuel_expense_draft.dart';

enum KmUpdateStatus { initial, loading, success, failure }

class KmUpdateState extends Equatable {
  final KmUpdateStatus status;
  final int? savedKm; // km effettivi salvati (ritornati dalla RPC)
  final String? error;

  const KmUpdateState({
    this.status = KmUpdateStatus.initial,
    this.savedKm,
    this.error,
  });

  KmUpdateState copyWith({
    KmUpdateStatus? status,
    int? savedKm,
    String? error,
  }) {
    return KmUpdateState(
      status: status ?? this.status,
      savedKm: savedKm ?? this.savedKm,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, savedKm, error];
}

/// Cubit della modale "Aggiorna KM": una sola azione asincrona con stati
/// loading / success / failure, così la UI mostra spinner ed errori.
class KmUpdateCubit extends Cubit<KmUpdateState> {
  final UpdateVehicleKm updateVehicleKm;
  final AddFuelExpense addFuelExpense;

  KmUpdateCubit(this.updateVehicleKm, this.addFuelExpense)
    : super(const KmUpdateState());

  Future<void> aggiorna({
    required String vehicleId,
    required int newKm,
    FuelExpenseDraft? fuelExpense,
  }) async {
    emit(state.copyWith(status: KmUpdateStatus.loading, error: null));
    final kmResult = await updateVehicleKm(vehicleId: vehicleId, newKm: newKm);
    final kmFailure = kmResult.getLeft().toNullable();
    if (kmFailure != null) {
      emit(
        state.copyWith(
          status: KmUpdateStatus.failure,
          error: kmFailure.message,
        ),
      );
      return;
    }

    final savedKm = kmResult.toNullable()!;
    if (fuelExpense != null) {
      final fuelResult = await addFuelExpense(
        vehicleId: vehicleId,
        expense: fuelExpense,
      );
      final fuelFailure = fuelResult.getLeft().toNullable();
      if (fuelFailure != null) {
        emit(
          state.copyWith(
            status: KmUpdateStatus.failure,
            savedKm: savedKm,
            error: fuelFailure.message,
          ),
        );
        return;
      }
    }

    emit(state.copyWith(status: KmUpdateStatus.success, savedKm: savedKm));
  }
}
