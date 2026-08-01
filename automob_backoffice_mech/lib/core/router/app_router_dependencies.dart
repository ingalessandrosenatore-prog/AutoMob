import 'package:flutter/widgets.dart';

import 'auth_navigation_status.dart';

typedef RouteWidgetBuilder = Widget Function(BuildContext context);
typedef VehicleRouteWidgetBuilder =
    Widget Function(BuildContext context, String vehicleId);
typedef WorkRouteWidgetBuilder =
    Widget Function(BuildContext context, String vehicleId, String workId);

class AppRouterDependencies {
  const AppRouterDependencies({
    required this.authStatus,
    required this.authRefreshListenable,
    required this.splash,
    required this.login,
    required this.registration,
    required this.emailVerification,
    required this.workshop,
    required this.subscription,
    required this.vehicleConfiguration,
    required this.workRegistration,
    required this.workDetail,
  });

  final AuthNavigationStatus Function() authStatus;
  final Listenable authRefreshListenable;
  final RouteWidgetBuilder splash;
  final RouteWidgetBuilder login;
  final RouteWidgetBuilder registration;
  final RouteWidgetBuilder emailVerification;
  final RouteWidgetBuilder workshop;
  final RouteWidgetBuilder subscription;
  final VehicleRouteWidgetBuilder vehicleConfiguration;
  final VehicleRouteWidgetBuilder workRegistration;
  final WorkRouteWidgetBuilder workDetail;
}
