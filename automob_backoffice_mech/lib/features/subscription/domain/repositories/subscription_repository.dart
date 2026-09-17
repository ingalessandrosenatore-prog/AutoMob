import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/subscription_overview.dart';

abstract interface class SubscriptionRepository {
  Future<Either<Failure, SubscriptionOverview>> getOverview();
}
