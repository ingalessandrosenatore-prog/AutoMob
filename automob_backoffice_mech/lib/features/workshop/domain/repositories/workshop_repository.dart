import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/workshop_catalog.dart';

abstract interface class WorkshopRepository {
  Future<Either<Failure, WorkshopCatalog>> getCatalog();
}
