import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
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
}
