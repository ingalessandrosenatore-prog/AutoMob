import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/mechanic_registration.dart';
import '../models/app_auth_user_model.dart';
import '../models/registration_response_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<RegistrationResponseModel> registerMechanic(
    MechanicRegistration registration,
  );

  AppAuthUserModel? checkSession();
}

final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this.client);

  final SupabaseClient client;

  static const emailConfirmationRedirect =
      'com.infinty.automob.mechanic://login-callback/';

  @override
  Future<RegistrationResponseModel> registerMechanic(
    MechanicRegistration registration,
  ) async {
    try {
      final mechanicCode =
          'AM-${const Uuid().v4().replaceAll('-', '').substring(0, 10).toUpperCase()}';
      final response = await client.auth.signUp(
        email: registration.email.trim(),
        password: registration.password,
        emailRedirectTo: emailConfirmationRedirect,
        data: {
          'role': 'meccanico',
          'full_name': registration.fullName.trim(),
          'phone': registration.phone.trim(),
          'mechanic_code': mechanicCode,
          'business_name': registration.businessName.trim(),
          'vat_number': registration.vatNumber.trim(),
          'address': registration.legacyAddress,
          'street_address': registration.streetAddress.trim(),
          'postal_code': registration.postalCode.trim(),
          'municipality_istat_code': registration.municipalityIstatCode,
        },
      );
      final user = response.user;
      if (user == null) {
        throw const AuthDataException('Registrazione non completata');
      }
      return RegistrationResponseModel(
        user: AppAuthUserModel.fromSupabase(user),
        requiresEmailConfirmation: response.session == null,
      );
    } on AuthException catch (error) {
      throw AuthDataException(error.message, code: error.code);
    } on SocketException {
      throw const NetworkException();
    }
  }

  @override
  AppAuthUserModel? checkSession() {
    final user = client.auth.currentSession?.user;
    return user == null ? null : AppAuthUserModel.fromSupabase(user);
  }
}
