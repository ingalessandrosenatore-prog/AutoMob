import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/update_vehicle_km.dart';

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

  KmUpdateCubit(this.updateVehicleKm) : super(const KmUpdateState());

  Future<void> aggiorna({required String vehicleId, required int newKm}) async {
    emit(state.copyWith(status: KmUpdateStatus.loading, error: null));
    final res = await updateVehicleKm(vehicleId: vehicleId, newKm: newKm);
    res.fold(
      (f) => emit(
        state.copyWith(status: KmUpdateStatus.failure, error: f.message),
      ),
      (km) => emit(state.copyWith(status: KmUpdateStatus.success, savedKm: km)),
    );
  }
}
