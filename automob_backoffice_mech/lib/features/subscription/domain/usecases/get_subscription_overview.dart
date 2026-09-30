import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/subscription_overview.dart';
import '../repositories/subscription_repository.dart';

final class GetSubscriptionOverview {
  const GetSubscriptionOverview(this.repository);

  final SubscriptionRepository repository;

  Future<Either<Failure, SubscriptionOverview>> call() =>
      repository.getOverview();
}
