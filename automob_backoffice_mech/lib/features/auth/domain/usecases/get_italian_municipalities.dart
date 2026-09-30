import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/italian_municipality.dart';
import '../repositories/auth_repository.dart';

final class GetItalianMunicipalities {
  const GetItalianMunicipalities(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, List<ItalianMunicipality>>> call() =>
      repository.getMunicipalities();
}
