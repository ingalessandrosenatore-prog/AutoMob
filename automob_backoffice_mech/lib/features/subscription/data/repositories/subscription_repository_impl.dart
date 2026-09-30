import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/subscription_overview.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_data_source.dart';

final class SubscriptionRepositoryImpl implements SubscriptionRepository {
  const SubscriptionRepositoryImpl(this.dataSource);

  final SubscriptionDataSource dataSource;

  @override
  Future<Either<Failure, SubscriptionOverview>> getOverview() async {
    try {
      return Right((await dataSource.getOverview()).toEntity());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
