import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/vehicle_repository.dart';

/// Aggiorna (sovrascrive) la foto locale di un veicolo già esistente.
class UpdateVehiclePhoto {
  final VehicleRepository repository;

  UpdateVehiclePhoto(this.repository);

  Future<Either<Failure, void>> call({
    required String targa,
    required File foto,
  }) {
    return repository.updateVehiclePhoto(targa: targa, foto: foto);
  }
}
