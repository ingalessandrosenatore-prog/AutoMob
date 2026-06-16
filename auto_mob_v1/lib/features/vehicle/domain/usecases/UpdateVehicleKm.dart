import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../repositories/VehicleRepository.dart';

/// Aggiorna i km del veicolo (modale "Aggiorna KM", senza lavoro).
/// Ritorna i km effettivi salvati (salgono solo, mai indietro).
class UpdateVehicleKm {
  final VehicleRepository repository;

  UpdateVehicleKm(this.repository);

  Future<Either<Failure, int>> call({
    required String vehicleId,
    required int newKm,
  }) {
    return repository.updateKm(vehicleId: vehicleId, newKm: newKm);
  }
}
