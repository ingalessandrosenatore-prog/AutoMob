import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions/exceptions.dart';
import '../../domain/entities/owner_registration.dart';

class OwnerAccessRemoteDataSource {
  const OwnerAccessRemoteDataSource(this.client);
  final SupabaseClient client;

  Future<OwnerAccess> resolve({OwnerRegistration? registration}) async {
    final response = await client.functions.invoke(
      'complete-owner-registration',
      body: {
        'action': registration == null ? 'inspect' : 'complete',
        if (registration != null) ...{
          'full_name': registration.fullName.trim(),
          'phone': registration.phone.trim(),
          'postal_code': registration.postalCode.trim(),
        },
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['status'] != 'ready' && data['status'] != 'incomplete') {
      throw const AuthDataSourceException('Profilo non disponibile. Riprova.');
    }
    final profile = Map<String, dynamic>.from(data['profile'] as Map);
    return OwnerAccess(
      needsCompletion: data['status'] == 'incomplete',
      profile: OwnerRegistration(
        fullName: profile['full_name'] as String? ?? '',
        phone: profile['phone'] as String? ?? '',
        postalCode: profile['postal_code'] as String? ?? '',
      ),
    );
  }
}
