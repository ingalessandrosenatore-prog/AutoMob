import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/vehicle_lookup_result.dart';

/// Recupero dati veicolo a partire dalla targa. Oggi implementato con dati
/// mock (nessuna API esterna reale) — la firma resta la stessa quando si
/// integrerà un servizio reale (es. motorizzazione/targa.it).
abstract class VehicleLookupRepository {
  Future<Either<Failure, VehicleLookupResult>> lookupByPlate(String targa);
}
