import 'package:fpdart/fpdart.dart';

import '../entities/mechanic_summary.dart';
import '../entities/vehicle_lookup_result.dart';
import '../failures/vehicle_lookup_failure.dart';

/// Recupero dati veicolo a partire dalla targa. Oggi implementato con dati
/// mock (nessuna API esterna reale) — la firma resta la stessa quando si
/// integrerà un servizio reale (es. motorizzazione/targa.it).
abstract class VehicleLookupRepository {
  Future<Either<VehicleLookupFailure, VehicleLookupResult>> lookupByPlate(
    String targa,
  );
  Future<Either<VehicleLookupFailure, MechanicSummary?>> lookupMechanicByCode(
    String code,
  );
}
