import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/vehicle.dart';
import '../entities/vehicle_draft.dart';

abstract class VehicleRepository {
  /// Salva (o aggiorna) il draft corrente in locale (SharedPreferences).
  Future<Either<Failure, void>> saveDraftStep(VehicleDraft draft);

  /// Salva il veicolo completo su Supabase: anagrafica + storici manutenzione +
  /// (opzionale) assegnazione meccanico. Rollback automatico in caso di errore.
  /// L'ownerId viene letto dalla sessione Supabase corrente nel layer data.
  Future<Either<Failure, void>> saveVehicle(VehicleDraft draft);

  /// Restituisce tutti i veicoli accessibili dall'utente corrente
  /// (RLS lato DB filtra per owner_id).
  Future<Either<Failure, List<Vehicle>>> getVehicles();

  /// Aggiorna i km del veicolo (senza lavoro). Ritorna i km effettivi salvati
  /// (i km salgono solo, mai indietro).
  Future<Either<Failure, int>> updateKm({
    required String vehicleId,
    required int newKm,
  });

  /// Sovrascrive la foto locale di un veicolo già esistente, riusando la
  /// stessa convenzione di naming di saveVehicle (nessuna chiamata remota).
  Future<Either<Failure, void>> updateVehiclePhoto({
    required String targa,
    required File foto,
  });
}
