import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vehicle_lookup_result.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../../domain/usecases/clear_vehicle_draft.dart';
import '../../domain/usecases/load_vehicle_draft.dart';
import '../../domain/usecases/lookup_mechanic_by_code.dart';
import '../../domain/usecases/lookup_vehicle_by_plate.dart';
import '../../domain/usecases/save_draft_step.dart';
import '../../domain/usecases/save_vehicle.dart';
import 'vehicle_registration_event.dart';
import 'vehicle_registration_state.dart';

class VehicleRegistrationBloc
    extends Bloc<VehicleRegistrationEvent, VehicleRegistrationState> {
  final LookupVehicleByPlate lookupVehicleByPlate;
  final LookupMechanicByCode lookupMechanicByCode;
  final SaveDraftStep saveDraftStep;
  final LoadVehicleDraft loadVehicleDraft;
  final ClearVehicleDraft clearVehicleDraft;
  final SaveVehicle saveVehicle;

  VehicleRegistrationBloc({
    required this.lookupVehicleByPlate,
    required this.lookupMechanicByCode,
    required this.saveDraftStep,
    required this.loadVehicleDraft,
    required this.clearVehicleDraft,
    required this.saveVehicle,
  }) : super(const VehicleRegistrationState()) {
    on<RegistrationStarted>(_onStarted);
    on<MechanicStepSubmitted>(_onMechanicStep);
    on<RegistrationWithoutMechanicPressed>(_onWithoutMechanic);
    on<PlateSubmitted>(_onPlateSubmitted);
    on<ManualPlateSubmitted>(_onManualPlateSubmitted);
    on<LookupClosedWithManualEntry>(_onManualEntry);
    on<LookupDialogAcknowledged>(_onLookupDialogAcknowledged);
    on<VerifyStepSubmitted>(_onVerifyStep);
    on<WorkLogStepSubmitted>(_onWorkLogStep);
    on<PhotoStepSubmitted>(_onPhotoStep);
    on<RegistrationStepBackPressed>(_onStepBack);
    on<RegistrationDraftDiscarded>(_onDiscard);
    on<RegistrationDraftSaveRequested>(_onSaveDraft);
  }

  Future<void> _persist(VehicleDraft draft) async => saveDraftStep(draft);

  Future<void> _onStarted(
    RegistrationStarted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final result = await loadVehicleDraft();
    result.fold((_) => emit(const VehicleRegistrationState()), (draft) {
      if (draft == null) return emit(const VehicleRegistrationState());
      // Nel flusso manuale una targa gia' salvata significa che si puo'
      // riprendere direttamente dalla compilazione dei dati del veicolo.
      final step = (draft.targa?.isNotEmpty ?? false) ? 2 : 0;
      emit(VehicleRegistrationState(currentStep: step, draft: draft));
    });
  }

  Future<void> _onMechanicStep(
    MechanicStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final code = event.codiceMeccanico?.trim();
    if (code == null || code.isEmpty) return _advanceWithoutMechanic(emit);
    emit(state.copyWith(mechanicStatus: MechanicLookupStatus.loading));
    final result = await lookupMechanicByCode(code);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          mechanicStatus: MechanicLookupStatus.failure,
          message: failure.message,
        ),
      ),
      (mechanic) async {
        if (mechanic == null) {
          emit(
            state.copyWith(
              mechanicStatus: MechanicLookupStatus.notFound,
              message: 'Codice meccanico non valido o officina non attiva.',
            ),
          );
          return;
        }
        final draft = state.draft.copyWith(
          codiceMeccanico: mechanic.code,
          meccanicoId: mechanic.id,
          meccanicoNome: mechanic.businessName,
          meccanicoIndirizzo: mechanic.address,
        );
        await _persist(draft);
        emit(
          state.copyWith(
            currentStep: 1,
            draft: draft,
            mechanicStatus: MechanicLookupStatus.found,
            clearMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onWithoutMechanic(
    RegistrationWithoutMechanicPressed event,
    Emitter<VehicleRegistrationState> emit,
  ) => _advanceWithoutMechanic(emit);

  Future<void> _advanceWithoutMechanic(
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final draft = state.draft.copyWith(
      codiceMeccanico: null,
      meccanicoId: null,
      meccanicoNome: null,
      meccanicoIndirizzo: null,
    );
    await _persist(draft);
    emit(
      state.copyWith(
        currentStep: 1,
        draft: draft,
        mechanicStatus: MechanicLookupStatus.idle,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onPlateSubmitted(
    PlateSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    if (state.draft.lookupAttemptConsumed) {
      emit(
        state.copyWith(
          currentStep: 2,
          lookupStatus: RegistrationLookupStatus.idle,
          clearLookupFailure: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        lookupStatus: RegistrationLookupStatus.loading,
        clearLookupFailure: true,
      ),
    );
    final result = await lookupVehicleByPlate(event.targa);
    await result.fold(
      (failure) async {
        final consumed = failure.consumesAttempt;
        final draft = state.draft.copyWith(
          targa: event.targa
              .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
              .toUpperCase(),
          lookupAttemptConsumed: consumed,
          datiInModifica: consumed,
        );
        if (consumed) await _persist(draft);
        emit(
          state.copyWith(
            currentStep: consumed ? 2 : 1,
            draft: draft,
            lookupStatus: RegistrationLookupStatus.failure,
            lookupFailure: failure,
          ),
        );
      },
      (found) async {
        final partial = found.quality == VehicleLookupQuality.partial;
        final draft = state.draft.copyWith(
          targa: found.plate,
          marca: found.marca,
          modello: found.modello,
          anno: found.anno,
          carburante: found.carburante,
          cilindrata: found.cilindrata,
          potenzaCv: found.potenzaCv,
          lookupId: found.lookupId,
          lookupAttemptConsumed: true,
          datiInModifica: partial,
        );
        await _persist(draft);
        emit(
          state.copyWith(
            currentStep: 2,
            draft: draft,
            lookupStatus: partial
                ? RegistrationLookupStatus.partial
                : RegistrationLookupStatus.complete,
          ),
        );
      },
    );
  }

  Future<void> _onManualPlateSubmitted(
    ManualPlateSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final plate = event.targa
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (!RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$').hasMatch(plate)) return;

    final draft = state.draft.copyWith(
      targa: plate,
      lookupId: null,
      lookupAttemptConsumed: false,
      datiInModifica: true,
    );
    await _persist(draft);
    emit(
      state.copyWith(
        currentStep: 2,
        draft: draft,
        lookupStatus: RegistrationLookupStatus.idle,
        clearLookupFailure: true,
      ),
    );
  }

  Future<void> _onManualEntry(
    LookupClosedWithManualEntry event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final draft = state.draft.copyWith(datiInModifica: true);
    await _persist(draft);
    emit(
      state.copyWith(
        currentStep: 2,
        draft: draft,
        lookupStatus: RegistrationLookupStatus.idle,
        clearLookupFailure: true,
      ),
    );
  }

  void _onLookupDialogAcknowledged(
    LookupDialogAcknowledged event,
    Emitter<VehicleRegistrationState> emit,
  ) {
    emit(
      state.copyWith(
        lookupStatus: RegistrationLookupStatus.idle,
        clearLookupFailure: true,
      ),
    );
  }

  Future<void> _onVerifyStep(
    VerifyStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final normalized = event.targa
        ?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final plateChanged = normalized != null && normalized != state.draft.targa;
    final draft = state.draft.copyWith(
      targa: normalized,
      marca: event.marca,
      modello: event.modello,
      anno: event.anno,
      carburante: event.carburante,
      cilindrata: event.cilindrata,
      potenzaCv: event.potenzaCv,
      lookupId: plateChanged ? null : state.draft.lookupId,
    );
    await _persist(draft);
    emit(state.copyWith(draft: draft, currentStep: 3));
  }

  Future<void> _onWorkLogStep(
    WorkLogStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
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
    await _persist(draft);
    emit(state.copyWith(draft: draft, currentStep: 4));
  }

  Future<void> _onPhotoStep(
    PhotoStepSubmitted event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final draft = state.draft.copyWith(fotoFile: event.fotoFile);
    await _persist(draft);
    emit(state.copyWith(draft: draft, status: RegistrationStatus.loading));
    final result = await saveVehicle(draft);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          message: failure.message,
        ),
      ),
      (outcome) async {
        await clearVehicleDraft();
        emit(
          state.copyWith(
            status: RegistrationStatus.completed,
            photoWarning: !outcome.photoSaved,
            clearMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onStepBack(
    RegistrationStepBackPressed event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    final previous = state.currentStep - 1;
    emit(state.copyWith(currentStep: previous < 0 ? 0 : previous));
  }

  Future<void> _onDiscard(
    RegistrationDraftDiscarded event,
    Emitter<VehicleRegistrationState> emit,
  ) async {
    await clearVehicleDraft();
    emit(const VehicleRegistrationState());
  }

  Future<void> _onSaveDraft(
    RegistrationDraftSaveRequested event,
    Emitter<VehicleRegistrationState> emit,
  ) => _persist(state.draft);
}
