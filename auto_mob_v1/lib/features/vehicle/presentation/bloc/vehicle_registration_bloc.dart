import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/lookup_vehicle_by_plate.dart';

import 'vehicle_registration_event.dart';
import 'vehicle_registration_state.dart';

class VehicleRegistrationBloc
    extends Bloc<VehicleRegistrationEvent, VehicleRegistrationState> {
  final LookupVehicleByPlate lookupVehicleByPlate;

  VehicleRegistrationBloc({required this.lookupVehicleByPlate})
    : super(const VehicleRegistrationState()) {
    on<RegistrationStarted>(_onStarted);
    on<MechanicStepSubmitted>(_onMechanicStep);
    on<PlateSubmitted>(_onPlateSubmitted);
    on<VerifyStepSubmitted>(_onVerifyStep);
    on<WorkLogStepSubmitted>(_onWorkLogStep);
    on<PhotoStepSubmitted>(_onPhotoStep);
    on<RegistrationStepBackPressed>(_onStepBack);
  }

  FutureOr<void> _onStarted(
    RegistrationStarted event,
    Emitter<VehicleRegistrationState> emit,
  ) {
    emit(const VehicleRegistrationState());
  }

  void _onMechanicStep(
    MechanicStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) {
    final draft = state.draft.copyWith(codiceMeccanico: event.codiceMeccanico);
    emit(state.copyWith(draft: draft, currentStep: state.currentStep + 1));
  }

  Future<void> _onPlateSubmitted(
    PlateSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final draftConTarga = state.draft.copyWith(targa: event.targa);
    emit(
      state.copyWith(
        draft: draftConTarga,
        lookupStatus: RegistrationLookupStatus.loading,
      ),
    );

    final result = await lookupVehicleByPlate(event.targa);
    result.fold(
      (_) => emit(
        state.copyWith(
          currentStep: state.currentStep + 1,
          lookupStatus: RegistrationLookupStatus.notFound,
        ),
      ),
      (found) => emit(
        state.copyWith(
          draft: draftConTarga.copyWith(
            marca: found.marca,
            modello: found.modello,
            anno: found.anno,
            carburante: found.carburante,
            cilindrata: found.cilindrata,
          ),
          currentStep: state.currentStep + 1,
          lookupStatus: RegistrationLookupStatus.success,
        ),
      ),
    );
  }

  void _onVerifyStep(
    VerifyStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) {
    final draft = state.draft.copyWith(
      marca: event.marca,
      modello: event.modello,
      anno: event.anno,
      carburante: event.carburante,
      cilindrata: event.cilindrata,
    );
    emit(state.copyWith(draft: draft, currentStep: state.currentStep + 1));
  }

  void _onWorkLogStep(
    WorkLogStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) {
    final draft = state.draft.copyWith(
      kmAttuali: event.kmAttuali,
      intervalloUltimoTagliando: event.intervalloTagliando,
      kmUltimoTagliando: event.kmUltimoTagliando,
      intervalloUltimaDistribuzione: event.intervalloUltimaDistribuzione,
      kmUltimaDistribuzione: event.kmUltimaDistribuzione,
      prossimarevisione: event.prossimarevisione,
      kmUltimoCambioGomme: event.kmUltimoCambioGomme,
      intervalloCambioGomme: event.intervalloCambioGomme,
      kmUltimaInversioneGomme: event.kmUltimaInversioneGomme,
      intervalloInversioneGomme: event.intervalloInversioneGomme,
    );
    emit(state.copyWith(draft: draft, currentStep: state.currentStep + 1));
  }

  void _onPhotoStep(
    PhotoStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) {
    final draft = state.draft.copyWith(fotoFile: event.fotoFile);
    emit(state.copyWith(draft: draft, status: RegistrationStatus.completed));
  }

  void _onStepBack(
    RegistrationStepBackPressed event,
    Emitter<VehicleRegistrationState> emit,
  ) {
    final previous = state.currentStep - 1;
    emit(state.copyWith(currentStep: previous < 0 ? 0 : previous));
  }
}
