import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../../domain/usecases/save_draft_step.dart';
import '../../domain/usecases/save_vehicle.dart';

import 'add_vehicle_event.dart';
import 'add_vehicle_state.dart';

class AddVehicleBloc extends Bloc<AddVehicleEvent, AddVehicleState> {
  final SaveDraftStep saveDraftStep;
  final SaveVehicle saveVehicle;

  AddVehicleBloc({
    required this.saveDraftStep,
    required this.saveVehicle,
  }) : super(const AddVehicleState()) {
    on<AddVehicleStarted>(_onStep0);
    on<Step1Submitted>(_onStep1);
    on<Step2Submitted>(_onStep2);
    on<Step3Submitted>(_onStep3);
    on<Step4Submitted>(_onStep4);
    on<SaveWizard>(_onSaveWizard);
    on<StepBackPressed>(_onStepBack);
  }

  /// null = successo, Failure = errore con messaggio
  Future<Failure?> _persist(VehicleDraft draft) async {
    final result = await saveDraftStep(draft);
    return result.fold((failure) => failure, (_) => null);
  }

  Future<void> _onStep1(Step1Submitted event, Emitter<AddVehicleState> emit) async {
    final draft = state.draft.copyWith(
      marca: event.marca,
      modello: event.modello,
      carburante: event.carburante,
      targa: event.targa,
      anno: event.year,
    );
    emit(state.copyWith(draft: draft, status: AddVehicleStatus.loading));
    final failure = await _persist(draft);
    if (failure == null) {
      emit(state.copyWith(currentStep: state.currentStep + 1, status: AddVehicleStatus.idle));
    } else {
      emit(state.copyWith(status: AddVehicleStatus.error, errorMessage: failure.message));
    }
  }

  Future<void> _onStep2(Step2Submitted event, Emitter<AddVehicleState> emit) async {
    final draft = state.draft.copyWith(
      intervalloUltimoTagliando: event.intervalloTagliando,
      kmUltimoTagliando: event.kmUltimoTagliando,
      intervalloUltimaDistribuzione: event.intervalloUltimaDistribuzione,
      kmUltimaDistribuzione: event.kmUltimaDistribuzione,
    );
    emit(state.copyWith(draft: draft, status: AddVehicleStatus.loading));
    final failure = await _persist(draft);
    if (failure == null) {
      emit(state.copyWith(currentStep: state.currentStep + 1, status: AddVehicleStatus.idle));
    } else {
      emit(state.copyWith(status: AddVehicleStatus.error, errorMessage: failure.message));
    }
  }

  Future<void> _onStep3(Step3Submitted event, Emitter<AddVehicleState> emit) async {
    final draft = state.draft.copyWith(
      potenzaCv: event.potenzaCv,
      cilindrata: event.cilindrata,
      kmAttuali: event.kmAttuali,
    );
    emit(state.copyWith(draft: draft, status: AddVehicleStatus.loading));
    final failure = await _persist(draft);
    if (failure == null) {
      emit(state.copyWith(currentStep: state.currentStep + 1, status: AddVehicleStatus.idle));
    } else {
      emit(state.copyWith(status: AddVehicleStatus.error, errorMessage: failure.message));
    }
  }

  Future<void> _onStep4(Step4Submitted event, Emitter<AddVehicleState> emit) async {
    final draft = state.draft.copyWith(
      prossimarevisione: event.prossimarevisione,
      kmUltimoCambioGomme: event.kmUltimoCambioGomme,
      intervalloCambioGomme: event.intervalloCambioGomme,
      kmUltimaInversioneGomme: event.kmUltimaInversioneGomme,
      intervalloInversioneGomme: event.intervalloInversioneGomme,
    );
    emit(state.copyWith(draft: draft, status: AddVehicleStatus.loading));
    final failure = await _persist(draft);
    if (failure == null) {
      emit(state.copyWith(currentStep: state.currentStep + 1, status: AddVehicleStatus.idle));
    } else {
      emit(state.copyWith(status: AddVehicleStatus.error, errorMessage: failure.message));
    }
  }

  Future<void> _onSaveWizard(SaveWizard event, Emitter<AddVehicleState> emit) async {
    final draft = state.draft.copyWith(
      fotoFile: event.fotoFile ,
      codiceMeccanico: event.codiceMeccanico,
    );
    emit(state.copyWith(draft: draft, status: AddVehicleStatus.loading));

    // 1. Persisto il draft locale (così se la rete fallisce non si perde nulla allo step 5).
    final draftFailure = await _persist(draft);
    if (draftFailure != null) {
      emit(state.copyWith(status: AddVehicleStatus.error, errorMessage: draftFailure.message));
      return;
    }

    // 2. Salvo il veicolo su Supabase (anagrafica + storici + meccanico, con rollback in caso di errore).
    //    L'ownerId viene letto dalla sessione corrente direttamente nel datasource remoto.
    final result = await saveVehicle(draft);
    result.fold(
      (failure) => emit(state.copyWith(status: AddVehicleStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: AddVehicleStatus.completed)),
    );
  }

  void _onStepBack(StepBackPressed event, Emitter<AddVehicleState> emit) {
    emit(state.copyWith(currentStep: state.currentStep - 1, status: AddVehicleStatus.idle));
  }

  FutureOr<void> _onStep0(AddVehicleStarted event, Emitter<AddVehicleState> emit) {
    emit(state.copyWith(currentStep: 0));
  }
}
