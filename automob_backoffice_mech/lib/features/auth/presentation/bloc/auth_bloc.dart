import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/mechanic_registration.dart';
import '../../domain/entities/registration_outcome.dart';
import '../../domain/usecases/check_auth_session.dart';
import '../../domain/usecases/get_italian_municipalities.dart';
import '../../domain/usecases/get_pending_verification_email.dart';
import '../../domain/usecases/register_mechanic.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.registerMechanic,
    required this.checkAuthSession,
    required this.getPendingVerificationEmail,
    required this.getItalianMunicipalities,
  }) : super(const AuthBooting()) {
    on<AuthStarted>(_onStarted);
    on<FullNameChanged>(
      (event, emit) =>
          _updateDraft(emit, (draft) => draft.copyWith(fullName: event.value)),
    );
    on<EmailChanged>(
      (event, emit) =>
          _updateDraft(emit, (draft) => draft.copyWith(email: event.value)),
    );
    on<PhoneChanged>(
      (event, emit) =>
          _updateDraft(emit, (draft) => draft.copyWith(phone: event.value)),
    );
    on<PasswordChanged>(
      (event, emit) =>
          _updateDraft(emit, (draft) => draft.copyWith(password: event.value)),
    );
    on<PasswordConfirmationChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(passwordConfirmation: event.value),
      ),
    );
    on<BusinessNameChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(businessName: event.value),
      ),
    );
    on<VatNumberChanged>(
      (event, emit) =>
          _updateDraft(emit, (draft) => draft.copyWith(vatNumber: event.value)),
    );
    on<StreetAddressChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(streetAddress: event.value),
      ),
    );
    on<PostalCodeChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(postalCode: event.value),
      ),
    );
    on<MunicipalityChanged>(
      (event, emit) => _updateDraft(
        emit,
        (draft) => draft.copyWith(
          municipality: event.value,
          clearMunicipality: event.value == null,
        ),
      ),
    );
    on<RegistrationContinuePressed>(_onContinue);
    on<RegistrationBackPressed>(_onBack);
    on<EmailConfirmationPressed>(_onEmailConfirmationPressed);
    on<AuthDialogDismissed>(_onDialogDismissed);
  }

  final RegisterMechanic registerMechanic;
  final CheckAuthSession checkAuthSession;
  final GetPendingVerificationEmail getPendingVerificationEmail;
  final GetItalianMunicipalities getItalianMunicipalities;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthBooting());
    final sessionResult = await checkAuthSession();
    final user = sessionResult.getOrElse((_) => null);
    if (user != null) {
      emit(AuthAuthenticated(user));
      return;
    }
    final pendingResult = await getPendingVerificationEmail();
    final pendingEmail = pendingResult.getOrElse((_) => null);
    if (pendingEmail != null) {
      emit(AuthEmailVerificationPending(email: pendingEmail));
      return;
    }
    final municipalitiesResult = await getItalianMunicipalities();
    municipalitiesResult.fold(
      (failure) => emit(
        const AuthRegistration(
          step: RegistrationStep.personalData,
          draft: RegistrationDraft(),
          municipalities: [],
          dialogMessage: 'Impossibile caricare l’elenco dei comuni.',
        ),
      ),
      (municipalities) => emit(
        AuthRegistration(
          step: RegistrationStep.personalData,
          draft: const RegistrationDraft(),
          municipalities: municipalities,
        ),
      ),
    );
  }

  void _updateDraft(
    Emitter<AuthState> emit,
    RegistrationDraft Function(RegistrationDraft draft) update,
  ) {
    final current = state;
    if (current is! AuthRegistration || current.isSubmitting) return;
    emit(
      current.copyWith(
        draft: update(current.draft),
        errors: const RegistrationFieldErrors(),
        clearDialog: true,
      ),
    );
  }

  Future<void> _onContinue(
    RegistrationContinuePressed event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthRegistration || current.isSubmitting) return;
    if (current.step == RegistrationStep.personalData) {
      final errors = _validatePersonal(current.draft);
      if (errors.hasPersonalErrors) {
        emit(current.copyWith(errors: errors));
        return;
      }
      emit(
        current.copyWith(
          step: RegistrationStep.workshop,
          errors: const RegistrationFieldErrors(),
        ),
      );
      return;
    }

    final errors = _validateWorkshop(current.draft);
    if (errors.hasWorkshopErrors) {
      emit(current.copyWith(errors: errors));
      return;
    }
    emit(current.copyWith(status: RegistrationSubmissionStatus.submitting));
    final municipality = current.draft.municipality!;
    final result = await registerMechanic(
      MechanicRegistration(
        fullName: current.draft.fullName,
        email: current.draft.email,
        phone: current.draft.phone,
        password: current.draft.password,
        businessName: current.draft.businessName,
        vatNumber: current.draft.vatNumber,
        streetAddress: current.draft.streetAddress,
        postalCode: current.draft.postalCode,
        municipalityIstatCode: municipality.code,
        municipalityLabel: municipality.label,
      ),
    );
    result.fold(
      (failure) => emit(
        current.copyWith(
          status: RegistrationSubmissionStatus.idle,
          dialogMessage: failure.message,
        ),
      ),
      (outcome) => switch (outcome) {
        RegistrationAuthenticated(:final user) => emit(AuthAuthenticated(user)),
        RegistrationConfirmationRequired(:final email) => emit(
          AuthEmailVerificationPending(email: email),
        ),
      },
    );
  }

  void _onBack(RegistrationBackPressed event, Emitter<AuthState> emit) {
    final current = state;
    if (current is! AuthRegistration || current.isSubmitting) return;
    if (current.step == RegistrationStep.workshop) {
      emit(
        current.copyWith(
          step: RegistrationStep.personalData,
          errors: const RegistrationFieldErrors(),
        ),
      );
    }
  }

  Future<void> _onEmailConfirmationPressed(
    EmailConfirmationPressed event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthEmailVerificationPending || current.checking) return;
    emit(current.copyWith(checking: true, clearDialog: true));
    final result = await checkAuthSession();
    result.fold(
      (failure) => emit(
        current.copyWith(checking: false, dialogMessage: failure.message),
      ),
      (user) => emit(
        user == null
            ? current.copyWith(
                checking: false,
                dialogMessage:
                    'Non hai ancora confermato l’email. Apri il link ricevuto e riprova.',
              )
            : AuthAuthenticated(user),
      ),
    );
  }

  void _onDialogDismissed(AuthDialogDismissed event, Emitter<AuthState> emit) {
    switch (state) {
      case final AuthRegistration current:
        emit(current.copyWith(clearDialog: true));
      case final AuthEmailVerificationPending current:
        emit(current.copyWith(clearDialog: true));
      default:
        break;
    }
  }

  RegistrationFieldErrors _validatePersonal(RegistrationDraft draft) {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phone = draft.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return RegistrationFieldErrors(
      fullName: draft.fullName.trim().split(RegExp(r'\s+')).length < 2
          ? 'Inserisci nome e cognome.'
          : null,
      email: !emailPattern.hasMatch(draft.email.trim())
          ? 'Inserisci un’email valida.'
          : null,
      phone: phone.length < 8 ? 'Inserisci un numero valido.' : null,
      password: draft.password.length < 8 ? 'Usa almeno 8 caratteri.' : null,
      passwordConfirmation: draft.passwordConfirmation != draft.password
          ? 'Le password non coincidono.'
          : null,
    );
  }

  RegistrationFieldErrors _validateWorkshop(RegistrationDraft draft) =>
      RegistrationFieldErrors(
        businessName: draft.businessName.trim().isEmpty
            ? 'Inserisci il nome dell’officina.'
            : null,
        vatNumber: !RegExp(r'^\d{11}$').hasMatch(draft.vatNumber.trim())
            ? 'La Partita IVA deve avere 11 cifre.'
            : null,
        streetAddress: draft.streetAddress.trim().isEmpty
            ? 'Inserisci via e numero civico.'
            : null,
        postalCode: !RegExp(r'^\d{5}$').hasMatch(draft.postalCode.trim())
            ? 'Il CAP deve avere 5 cifre.'
            : null,
        municipality: draft.municipality == null
            ? 'Seleziona il comune.'
            : null,
      );
}
