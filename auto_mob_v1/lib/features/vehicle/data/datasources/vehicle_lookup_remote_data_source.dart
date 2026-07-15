import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/mechanic_summary.dart';
import '../../domain/entities/vehicle_lookup_result.dart';
import '../../domain/failures/vehicle_lookup_failure.dart';

class VehicleLookupDataSourceException implements Exception {
  final VehicleLookupFailure failure;
  const VehicleLookupDataSourceException(this.failure);
}

abstract class VehicleLookupRemoteDataSource {
  Future<VehicleLookupResult> lookupByPlate(String plate);
  Future<MechanicSummary?> lookupMechanicByCode(String code);
}

class VehicleLookupRemoteDataSourceImpl
    implements VehicleLookupRemoteDataSource {
  final SupabaseClient client;

  const VehicleLookupRemoteDataSourceImpl(this.client);

  @override
  Future<VehicleLookupResult> lookupByPlate(String plate) async {
    try {
      final response = await client.functions
          .invoke('vehicle-lookup', body: {'plate': plate})
          .timeout(const Duration(seconds: 15));
      final body = Map<String, dynamic>.from(response.data as Map);
      if (response.status < 200 ||
          response.status >= 300 ||
          body['success'] != true) {
        throw VehicleLookupDataSourceException(
          _failureFor(body['code'] as String?),
        );
      }
      final data = Map<String, dynamic>.from(body['data'] as Map);
      return VehicleLookupResult(
        lookupId: data['lookupId'] as String,
        quality: data['quality'] == 'complete'
            ? VehicleLookupQuality.complete
            : VehicleLookupQuality.partial,
        plate: data['plate'] as String,
        marca: data['brand'] as String?,
        modello: data['model'] as String?,
        anno: (data['year'] as num?)?.toInt(),
        carburante: data['fuel'] as String?,
        cilindrata: (data['displacementCc'] as num?)?.toInt(),
        potenzaCv: (data['powerCv'] as num?)?.toInt(),
        warnings: (data['warnings'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(growable: false),
      );
    } on TimeoutException {
      throw const VehicleLookupDataSourceException(TimeoutLookupFailure());
    } on SocketException {
      throw const VehicleLookupDataSourceException(NetworkLookupFailure());
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map ? details['code']?.toString() : null;
      throw VehicleLookupDataSourceException(_failureFor(code));
    } on VehicleLookupDataSourceException {
      rethrow;
    } catch (_) {
      throw const VehicleLookupDataSourceException(
        MalformedResponseLookupFailure(),
      );
    }
  }

  @override
  Future<MechanicSummary?> lookupMechanicByCode(String code) async {
    try {
      final row = await client
          .from('mechanics')
          .select('id, mechanic_code, business_name, address')
          .eq('mechanic_code', code.trim())
          .eq('is_active', true)
          .maybeSingle();
      if (row == null) return null;
      return MechanicSummary(
        id: row['id'] as String,
        code: row['mechanic_code'] as String,
        businessName: row['business_name'] as String,
        address: row['address'] as String?,
      );
    } on SocketException {
      throw const VehicleLookupDataSourceException(NetworkLookupFailure());
    } on PostgrestException {
      throw const VehicleLookupDataSourceException(ServerLookupFailure());
    }
  }

  VehicleLookupFailure _failureFor(String? code) => switch (code) {
    'invalid-plate' => const InvalidPlateLookupFailure(),
    'bad-request' || 'ER400' || '400' => const BadRequestLookupFailure(),
    'unauthorized' || 'ER401' || '401' => const UnauthorizedLookupFailure(),
    'forbidden' || 'ER403' || '403' => const ForbiddenLookupFailure(),
    'rate-limited' || 'ER429' || '429' => const RateLimitedLookupFailure(),
    'no-data' => const NoDataLookupFailure(),
    'proxy-timeout' || 'timeout' => const TimeoutLookupFailure(),
    'proxy-network-error' => const NetworkLookupFailure(),
    'configuration-error' ||
    'snapshot-save-failed' => const ServerLookupFailure(),
    'unexpected-error' || 'ER500' || '500' => const ServerLookupFailure(),
    _ => const MalformedResponseLookupFailure(),
  };
}
