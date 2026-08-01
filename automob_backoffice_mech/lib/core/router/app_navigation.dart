import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_route_names.dart';

extension AppNavigation on BuildContext {
  void goToLogin() => goNamed(AppRouteNames.login);

  void goToRegistration() => goNamed(AppRouteNames.registration);

  void goToWorkshop() => goNamed(AppRouteNames.workshop);

  void goToSubscription() => goNamed(AppRouteNames.subscription);

  Future<T?> pushVehicleConfiguration<T>(String vehicleId) => pushNamed<T>(
    AppRouteNames.vehicleConfiguration,
    pathParameters: {'vehicleId': vehicleId},
  );

  Future<T?> pushWorkRegistration<T>(String vehicleId) => pushNamed<T>(
    AppRouteNames.workRegistration,
    pathParameters: {'vehicleId': vehicleId},
  );

  Future<T?> pushWorkDetail<T>({
    required String vehicleId,
    required String workId,
  }) => pushNamed<T>(
    AppRouteNames.workDetail,
    pathParameters: {'vehicleId': vehicleId, 'workId': workId},
  );
}
