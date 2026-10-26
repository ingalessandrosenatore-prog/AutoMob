import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/warning_light_observation.dart';
import '../models/future_work_summary_model.dart';
import '../models/warning_light_observation_model.dart';

class FutureWorkDataSourceException implements Exception {
  const FutureWorkDataSourceException(this.message, {this.code});

  final String message;
  final String? code;
}

abstract class FutureWorkRemoteDataSource {
  Future<void> markDone(String recordId);
  Future<List<FutureWorkSummaryModel>> getLatestOpen();

  Future<String> createReport({
    required String vehicleId,
    required String description,
    String onboardMessage = '',
    List<WarningLightObservation> warningLights = const [],
    required DateTime reminderDate,
  });
}

class SupabaseFutureWorkRemoteDataSource implements FutureWorkRemoteDataSource {
  const SupabaseFutureWorkRemoteDataSource(this.client);

  final SupabaseClient client;

  @override
  Future<void> markDone(String recordId) async {
    try {
      await client.rpc(
        'complete_future_work_report',
        params: {'p_record_id': recordId},
      );
    } on PostgrestException catch (error) {
      throw FutureWorkDataSourceException(error.message, code: error.code);
    }
  }

  @override
  Future<List<FutureWorkSummaryModel>> getLatestOpen() async {
    try {
      final result = await client.rpc('get_owner_active_reports');
      return (result as List)
          .map(
            (row) => FutureWorkSummaryModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw FutureWorkDataSourceException(error.message, code: error.code);
    } on SocketException {
      rethrow;
    } catch (error) {
      throw FutureWorkDataSourceException(error.toString());
    }
  }

  @override
  Future<String> createReport({
    required String vehicleId,
    required String description,
    String onboardMessage = '',
    List<WarningLightObservation> warningLights = const [],
    required DateTime reminderDate,
  }) async {
    try {
      final result = await client.rpc(
        'create_future_work_report',
        params: {
          'p_vehicle_id': vehicleId,
          'p_description': description,
          'p_onboard_message': onboardMessage,
          'p_warning_lights': serializeWarningLights(warningLights),
          'p_reminder_date': _dateParam(reminderDate),
        },
      );
      final id = result?.toString();
      if (id == null || id.isEmpty) {
        throw const FutureWorkDataSourceException(
          'Il database non ha restituito la segnalazione creata.',
        );
      }
      return id;
    } on FutureWorkDataSourceException {
      rethrow;
    } on PostgrestException catch (error) {
      throw FutureWorkDataSourceException(error.message, code: error.code);
    } on SocketException {
      rethrow;
    } catch (error) {
      throw FutureWorkDataSourceException(error.toString());
    }
  }

  String _dateParam(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
