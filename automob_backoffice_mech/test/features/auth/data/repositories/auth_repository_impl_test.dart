import 'package:automob_backoffice_mech/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:automob_backoffice_mech/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:automob_backoffice_mech/features/auth/data/datasources/municipality_local_data_source.dart';
import 'package:automob_backoffice_mech/features/auth/data/models/app_auth_user_model.dart';
import 'package:automob_backoffice_mech/features/auth/data/models/registration_response_model.dart';
import 'package:automob_backoffice_mech/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/mechanic_registration.dart';
import 'package:automob_backoffice_mech/features/auth/domain/entities/registration_outcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockRemoteDataSource extends Mock
    implements AuthRemoteDataSource {}

final class _MockLocalDataSource extends Mock implements AuthLocalDataSource {}

final class _MockMunicipalityDataSource extends Mock
    implements MunicipalityLocalDataSource {}

void main() {
  const registration = MechanicRegistration(
    fullName: 'Mario Rossi',
    email: 'mario@rossi.it',
    phone: '+39 333 1234567',
    password: 'Password1!',
    businessName: 'Officina Rossi',
    vatNumber: '12345678901',
    streetAddress: 'Via Roma 10',
    postalCode: '00100',
    municipalityIstatCode: '058091',
    municipalityLabel: 'Roma (RM)',
  );

  setUpAll(() => registerFallbackValue(registration));

  test('salva la fase pendente quando Supabase richiede conferma', () async {
    final remote = _MockRemoteDataSource();
    final local = _MockLocalDataSource();
    final municipalities = _MockMunicipalityDataSource();
    when(() => remote.registerMechanic(registration)).thenAnswer(
      (_) async => const RegistrationResponseModel(
        user: AppAuthUserModel(id: 'user-1', email: 'mario@rossi.it'),
        requiresEmailConfirmation: true,
      ),
    );
    when(
      () => local.savePendingVerificationEmail(any()),
    ).thenAnswer((_) async {});
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      municipalityDataSource: municipalities,
    );

    final result = await repository.registerMechanic(registration);

    expect(
      result.getOrElse((_) => const RegistrationConfirmationRequired('errore')),
      isA<RegistrationConfirmationRequired>(),
    );
    verify(
      () => local.savePendingVerificationEmail('mario@rossi.it'),
    ).called(1);
    verifyNever(local.clearPendingVerificationEmail);
  });

  test('cancella la fase pendente quando trova una sessione', () async {
    final remote = _MockRemoteDataSource();
    final local = _MockLocalDataSource();
    final municipalities = _MockMunicipalityDataSource();
    when(
      remote.checkSession,
    ).thenReturn(const AppAuthUserModel(id: 'user-1', email: 'mario@rossi.it'));
    when(local.clearPendingVerificationEmail).thenAnswer((_) async {});
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      municipalityDataSource: municipalities,
    );

    final result = await repository.checkSession();

    expect(result.getOrElse((_) => null)?.id, 'user-1');
    verify(local.clearPendingVerificationEmail).called(1);
  });
}
