import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../../domain/entities/vehicle_lookup_result.dart';
import '../../domain/repositories/vehicle_lookup_repository.dart';

/// Implementazione MOCK: nessuna chiamata reale a un servizio esterno.
/// Simula una latenza di rete e restituisce dati fissi, cosi' da poter
/// costruire e testare tutta la UI del flusso di registrazione in attesa
/// di un'integrazione reale (es. motorizzazione/targa.it).
///
/// Una targa che contiene "FAIL" (case-insensitive) simula il caso
/// "veicolo non trovato", utile per testare il ramo di errore della UI.
class VehicleLookupRepositoryImpl implements VehicleLookupRepository {
  @override
  Future<Either<Failure, VehicleLookupResult>> lookupByPlate(
    String targa,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (targa.toUpperCase().contains('FAIL')) {
      return const Left(NotFoundFailure());
    }

    return const Right(
      VehicleLookupResult(
        marca: 'Fiat',
        modello: 'Panda',
        anno: 2019,
        carburante: 'Benzina',
        cilindrata: 1242,
      ),
    );
  }
}
