part of 'auth_bloc.dart';

extension _GoogleOwnerFlow on AuthBloc {
  Future<void> _onLoginWithGoogle(
    LoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthLoading ||
        state is AuthOwnerProfilePending ||
        state is AuthAuthenticated) {
      return;
    }
    final error = event.registration?.validate(requireName: false);
    if (error != null) {
      emit(AuthError(message: error));
      return;
    }
    final generation = ++_authGeneration;
    // The draft belongs only to this attempt. After process death the server's
    // pending profile brings the user back to the form, without stale PII reuse.
    _googleDraft = event.registration;
    emit(AuthLoading());
    final result = await loginWithGoogle();
    if (generation != _authGeneration || emit.isDone || state is! AuthLoading) {
      return;
    }
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthOAuthWaiting()),
    );
  }

  Future<void> _acceptUser(AppAuthUser user, Emitter<AuthState> emit) async {
    if (_loggingOut || _resolvingUser == user.id) return;
    final generation = ++_authGeneration;
    _resolvingUser = user.id;
    try {
      var result = await resolveOwnerAccess();
      if (generation != _authGeneration || emit.isDone) return;
      var profile = result.toOption().toNullable();
      final draft = _googleDraft;
      _googleDraft = null;
      if (profile != null && profile.needsCompletion && draft != null) {
        final registration = OwnerRegistration(
          fullName: profile.profile.fullName.isEmpty
              ? user.displayName
              : profile.profile.fullName,
          phone: draft.phone,
          postalCode: draft.postalCode,
        );
        if (registration.validate() == null) {
          result = await resolveOwnerAccess(registration: registration);
        } else {
          emit(AuthOwnerProfilePending(user: user, profile: registration));
          return;
        }
        profile = OwnerAccess(needsCompletion: true, profile: registration);
      }
      if (generation != _authGeneration || emit.isDone) return;
      await result.fold<Future<void>>(
        (failure) async {
          if (failure is PermissionFailure) {
            _loggingOut = true;
            await logout();
            _loggingOut = false;
            if (generation != _authGeneration || emit.isDone) return;
            emit(
              AuthError(
                message:
                    'Questo account è un profilo meccanico. Usa AutoMob Meccanico.',
              ),
            );
          } else {
            emit(
              AuthOwnerProfilePending(
                user: user,
                profile:
                    profile?.profile ??
                    OwnerRegistration(fullName: user.displayName),
                message: failure.message,
              ),
            );
          }
        },
        (access) async {
          if (access.needsCompletion) {
            emit(AuthOwnerProfilePending(user: user, profile: access.profile));
          } else {
            emit(
              AuthAuthenticated(
                user: AppAuthUser(
                  id: user.id,
                  email: user.email,
                  displayName: access.profile.fullName.isEmpty
                      ? user.displayName
                      : access.profile.fullName,
                ),
              ),
            );
          }
        },
      );
    } finally {
      if (_resolvingUser == user.id) _resolvingUser = null;
    }
  }

  Future<void> _onCompleteOwnerProfile(
    CompleteOwnerProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthOwnerProfilePending || current.busy) return;
    final generation = ++_authGeneration;
    emit(
      AuthOwnerProfilePending(
        user: current.user,
        profile: event.registration,
        busy: true,
      ),
    );
    final result = await resolveOwnerAccess(registration: event.registration);
    if (generation != _authGeneration || emit.isDone) return;
    result.fold(
      (failure) => emit(
        AuthOwnerProfilePending(
          user: current.user,
          profile: event.registration,
          message: failure.message,
        ),
      ),
      (access) => emit(
        access.needsCompletion
            ? AuthOwnerProfilePending(
                user: current.user,
                profile: access.profile,
              )
            : AuthAuthenticated(
                user: AppAuthUser(
                  id: current.user.id,
                  email: current.user.email,
                  displayName: access.profile.fullName,
                ),
              ),
      ),
    );
  }
}
