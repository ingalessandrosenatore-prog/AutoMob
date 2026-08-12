import 'dart:io';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions/exceptions.dart';

import '../../domain/entities/vehicle_draft.dart';
import '../../domain/entities/mechanic_summary.dart';
import '../../domain/entities/maintenance_defaults.dart';
import '../models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  /// Salva il veicolo (anagrafica) + lavori iniziali in modo ATOMICO,
  /// tramite l'RPC `crea_veicolo_con_storico` (una sola transazione: o si
  /// salva tutto o niente). L'ownerId NON viene inviato: lo imposta l'RPC
  /// da auth.uid() (l'utente loggato).
  Future<String> saveVehicle(VehicleDraft draft);

  /// Lista veicoli accessibili dall'utente corrente (RLS filtra per owner_id).
  Future<List<VehicleModel>> getVehicles();

  Future<MechanicSummary> connectMechanic({
    required String vehicleId,
    required String mechanicCode,
  });

  Future<void> disconnectMechanic({
    required String vehicleId,
    required String mechanicId,
  });

  /// Aggiorna i km del veicolo (modale "Aggiorna KM", senza lavoro) via RPC
  /// `aggiorna_km_veicolo`. I km salgono solo (mai indietro). Ritorna i km
  /// effettivi salvati sul DB.
  Future<int> updateKm({required String vehicleId, required int newKm});

  Future<DateTime> updateRevisionDate({
    required String vehicleId,
    required DateTime nextRevisionDate,
  });
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final SupabaseClient supabaseClient;
  // ignore: non_constant_identifier_names -- debito tecnico, vedi docs/TECH_DEBT.md
  String? get owner_id => supabaseClient.auth.currentUser?.id;

  VehicleRemoteDataSourceImpl({required this.supabaseClient});

  /// Converte le etichette dettagliate della UI nei valori canonici ammessi
  /// dal vincolo `vehicles.fuel_valid`.
  static String? normalizeFuel(String? value) {
    final fuel = value?.trim().toLowerCase();
    if (fuel == null || fuel.isEmpty) return null;
    if (fuel.contains('ibrido')) return 'ibrido';
    if (fuel.contains('gpl')) return 'gpl';
    if (fuel.contains('metano') || fuel.contains('cng')) return 'metano';
    if (fuel.contains('idrogeno')) return 'idrogeno';
    if (fuel.contains('elettrico')) return 'elettrico';
    if (fuel.contains('diesel')) return 'diesel';
    if (fuel.contains('benzina')) return 'benzina';
    return fuel;
  }

  @override
  Future<String> saveVehicle(VehicleDraft draft) async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      // Una sola chiamata: l'RPC inserisce veicolo + record + item in
      // transazione. Se qualcosa fallisce, il DB fa rollback di tutto.
      final result = await supabaseClient.rpc(
        'crea_veicolo_con_storico',
        params: {'p_payload': toSupabasePayload(draft)},
      );
      return result.toString();
    } on PostgrestException catch (e) {
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const VehicleDataSourceException(
        'Errore durante il salvataggio del veicolo',
      );
    }
  }

  @override
  Future<List<VehicleModel>> getVehicles() async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      // Leggo dalla VISTA "vista_veicoli_dashboard": ogni riga e' gia' un
      // veicolo completo di "ultimo intervento per tipo" (last_tagliando_km,
      // last_distribuzione_km, ...), calcolato lato DB partendo dai lavori.
      // UNA sola query, nessuna aggregazione in Dart.
      // Il filtro .eq('owner_id', ...) e' ridondante con la RLS (che gia'
      // mostra solo i miei veicoli), ma lo teniamo come secondo livello.
      final rows = await supabaseClient
          .from('vista_veicoli_dashboard')
          .select()
          .eq('owner_id', owner_id!);

      final vehicleRows = (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final vehicleIds = vehicleRows
          .map((row) => row['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      final mechanicsByVehicleId = <String, List<Map<String, dynamic>>>{};
      if (vehicleIds.isNotEmpty) {
        final links = await supabaseClient
            .from('vehicle_mechanics')
            .select(
              'vehicle_id, mechanic:mechanics('
              'id, mechanic_code, business_name, address, number, email'
              ')',
            )
            .inFilter('vehicle_id', vehicleIds)
            .order('assigned_at', ascending: false);

        for (final rawLink in links as List) {
          final link = Map<String, dynamic>.from(rawLink as Map);
          final vehicleId = link['vehicle_id']?.toString();
          final mechanic = link['mechanic'];
          if (vehicleId != null && mechanic is Map) {
            mechanicsByVehicleId
                .putIfAbsent(vehicleId, () => [])
                .add(Map<String, dynamic>.from(mechanic));
          }
        }
      }

      return vehicleRows.map((row) {
        final vehicleId = row['id']?.toString();
        return VehicleModel.fromJson({
          ...row,
          'mechanics': mechanicsByVehicleId[vehicleId] ?? const [],
        });
      }).toList();
    } on PostgrestException catch (e) {
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const VehicleDataSourceException(
        'Errore durante il caricamento dei veicoli',
      );
    }
  }

  @override
  Future<MechanicSummary> connectMechanic({
    required String vehicleId,
    required String mechanicCode,
  }) async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      final row = await supabaseClient
          .from('mechanics')
          .select('id, mechanic_code, business_name, address, number, email')
          .eq('mechanic_code', mechanicCode.trim())
          .eq('is_active', true)
          .maybeSingle();

      if (row == null) {
        throw const VehicleDataSourceException(
          'Codice meccanico non valido o officina non attiva.',
          code: 'mechanic_not_found',
        );
      }

      await supabaseClient.from('vehicle_mechanics').insert({
        'vehicle_id': vehicleId,
        'mechanic_id': row['id'],
      });

      return MechanicSummary(
        id: row['id'].toString(),
        code: row['mechanic_code'].toString(),
        businessName: row['business_name'].toString(),
        address: _nullableText(row['address']),
        phone: _nullableText(row['number']),
        email: _nullableText(row['email']),
      );
    } on VehicleDataSourceException {
      rethrow;
    } on PostgrestException catch (error) {
      throw VehicleDataSourceException(error.message, code: error.code);
    } on SocketException {
      throw const NetworkException();
    } catch (_) {
      throw const VehicleDataSourceException(
        'Errore durante il collegamento del meccanico',
      );
    }
  }

  @override
  Future<void> disconnectMechanic({
    required String vehicleId,
    required String mechanicId,
  }) async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      await supabaseClient
          .from('vehicle_mechanics')
          .delete()
          .eq('vehicle_id', vehicleId)
          .eq('mechanic_id', mechanicId);
    } on PostgrestException catch (error) {
      throw VehicleDataSourceException(error.message, code: error.code);
    } on SocketException {
      throw const NetworkException();
    } catch (_) {
      throw const VehicleDataSourceException(
        'Errore durante lo scollegamento dell\'officina',
      );
    }
  }

  @override
  Future<int> updateKm({required String vehicleId, required int newKm}) async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      // L'RPC fa GREATEST + controllo proprietario; il trigger DB registra
      // l'aggiornamento nello storico km. Ritorna i km effettivi salvati.
      final result = await supabaseClient.rpc(
        'aggiorna_km_veicolo',
        params: {'p_vehicle_id': vehicleId, 'p_nuovo_km': newKm},
      );
      return (result as num).toInt();
    } on PostgrestException catch (e) {
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const VehicleDataSourceException(
        'Errore durante l\'aggiornamento dei km',
      );
    }
  }

  @override
  Future<DateTime> updateRevisionDate({
    required String vehicleId,
    required DateTime nextRevisionDate,
  }) async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      final normalizedDate = DateTime(
        nextRevisionDate.year,
        nextRevisionDate.month,
        nextRevisionDate.day,
      );
      final dateParam = normalizedDate.toIso8601String().split('T')[0];
      developer.log(
        'UPDATE vehicles.scadenza_revision_date start '
        'vehicleId=$vehicleId date=$dateParam',
        name: 'AutoMob.VehicleRevision',
      );
      final row = await supabaseClient
          .from('vehicles')
          .update({'scadenza_revision_date': dateParam})
          .eq('id', vehicleId)
          .select('scadenza_revision_date')
          .single();
      final savedDate = DateTime.parse(
        row['scadenza_revision_date'].toString(),
      );
      developer.log(
        'UPDATE vehicles.scadenza_revision_date success '
        'vehicleId=$vehicleId savedDate=${savedDate.toIso8601String()}',
        name: 'AutoMob.VehicleRevision',
      );
      return savedDate;
    } on PostgrestException catch (e, stackTrace) {
      developer.log(
        'UPDATE vehicles.scadenza_revision_date PostgREST error '
        'vehicleId=$vehicleId code=${e.code} message=${e.message}',
        name: 'AutoMob.VehicleRevision',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      developer.log(
        'UPDATE vehicles.scadenza_revision_date network error '
        'vehicleId=$vehicleId',
        name: 'AutoMob.VehicleRevision',
        level: 1000,
      );
      throw const NetworkException();
    } catch (error, stackTrace) {
      developer.log(
        'UPDATE vehicles.scadenza_revision_date unexpected error '
        'vehicleId=$vehicleId',
        name: 'AutoMob.VehicleRevision',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      throw VehicleDataSourceException(
        'Errore durante l\'aggiornamento della revisione: $error',
      );
    }
  }

  /// Trasforma il draft nel payload JSON che si aspetta l'RPC
  /// `crea_veicolo_con_storico`: { "veicolo": {...}, "lavori": [...] }.
  /// Niente owner_id qui: lo imposta l'RPC da auth.uid().
  Map<String, dynamic> toSupabasePayload(VehicleDraft draft) {
    // 1) Anagrafica veicolo. Tutti gli intervalli ora arrivano ESPLICITI dal
    //    wizard (ultimo km + intervallo per ogni manutenzione).
    final veicolo = <String, dynamic>{
      'plate': draft.targa?.toLowerCase(),
      'brand': draft.marca?.toLowerCase(),
      'model': draft.modello?.toLowerCase(),
      'year': draft.anno,
      'fuel': normalizeFuel(draft.carburante),
      'km_current': draft.kmAttuali ?? MaintenanceDefaults.initialKm,
      'power_cv': draft.potenzaCv,
      'displacement_cc': draft.cilindrata,
      'tagliando_interval_km':
          draft.intervalloUltimoTagliando ??
          MaintenanceDefaults.tagliandoIntervalKm,
      'distribution_intervall_km':
          draft.intervalloUltimaDistribuzione ??
          MaintenanceDefaults.distribuzioneIntervalKm,
      'tire_change_interval_km':
          draft.intervalloCambioGomme ??
          MaintenanceDefaults.tireChangeIntervalKm,
      'tire_rotation_interval_km':
          draft.intervalloInversioneGomme ??
          MaintenanceDefaults.tireRotationIntervalKm,
      'scadenza_revision_date': draft.prossimarevisione
          ?.toIso8601String()
          .split('T')[0],
    };

    // 2) Lavori iniziali: un item per ogni manutenzione di cui conosciamo il km.
    final lavori = <Map<String, dynamic>>[
      {
        'type': 'tagliando',
        'service_km': draft.kmUltimoTagliando ?? MaintenanceDefaults.initialKm,
      },
      {
        'type': 'distribuzione',
        'service_km':
            draft.kmUltimaDistribuzione ?? MaintenanceDefaults.initialKm,
      },
      {
        'type': 'pneumatici_cambio',
        'service_km':
            draft.kmUltimoCambioGomme ?? MaintenanceDefaults.initialKm,
      },
      {
        'type': 'pneumatici_inversione',
        'service_km':
            draft.kmUltimaInversioneGomme ?? MaintenanceDefaults.initialKm,
      },
    ];

    return {
      'veicolo': veicolo,
      'lavori': lavori,
      'mechanic_id': draft.meccanicoId,
      'mechanic_code': draft.codiceMeccanico,
      'lookup_id': draft.lookupId,
    };
  }
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
