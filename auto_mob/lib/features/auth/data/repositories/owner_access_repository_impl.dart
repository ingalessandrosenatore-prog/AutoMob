import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions/exception.dart';
import '../../domain/entities/owner_registration.dart';
import '../../domain/repositories/owner_access_repository.dart';
import '../datasources/owner_access_remote_data_source.dart';

class OwnerAccessRepositoryImpl implements OwnerAccessRepository {
  const OwnerAccessRepositoryImpl(this.remote);
  final OwnerAccessRemoteDataSource remote;

  @override
  Future<Either<Failure, OwnerAccess>> resolve({
    OwnerRegistration? registration,
  }) async {
    try {
      return Right(await remote.resolve(registration: registration));
    } on FunctionException catch (error) {
      if (error.status == 403) return const Left(PermissionFailure());
      if (error.status == 401) {
        return const Left(AuthFailure('Sessione scaduta. Accedi di nuovo.'));
      }
      return const Left(
        RemoteFailure(
          'Impossibile verificare o salvare il profilo. Controlla i dati e riprova.',
        ),
      );
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }
}
