import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_route_names.dart';
import 'app_route_paths.dart';
import 'app_router_dependencies.dart';
import 'app_shell.dart';
import 'auth_navigation_status.dart';

GoRouter createAppRouter({required AppRouterDependencies dependencies}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final workshopNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'workshop',
  );
  final subscriptionNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'subscription',
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutePaths.splash,
    refreshListenable: dependencies.authRefreshListenable,
    redirect: (context, state) => _authRedirect(
      status: dependencies.authStatus(),
      location: state.uri.path,
    ),
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => dependencies.splash(context),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        builder: (context, state) => dependencies.login(context),
      ),
      GoRoute(
        path: AppRoutePaths.registration,
        name: AppRouteNames.registration,
        builder: (context, state) => dependencies.registration(context),
      ),
      GoRoute(
        path: AppRoutePaths.emailVerification,
        name: AppRouteNames.emailVerification,
        builder: (context, state) => dependencies.emailVerification(context),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: workshopNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.workshop,
                name: AppRouteNames.workshop,
                builder: (context, state) => dependencies.workshop(context),
                routes: [
                  GoRoute(
                    path: AppRoutePaths.vehicleConfigurationSegment,
                    name: AppRouteNames.vehicleConfiguration,
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        dependencies.vehicleConfiguration(
                          context,
                          state.pathParameters['vehicleId']!,
                          state.extra,
                        ),
                    routes: [
                      GoRoute(
                        path: AppRoutePaths.workRegistrationSegment,
                        name: AppRouteNames.workRegistration,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) =>
                            dependencies.workRegistration(
                              context,
                              state.pathParameters['vehicleId']!,
                              state.extra,
                            ),
                      ),
                      GoRoute(
                        path: AppRoutePaths.workDetailSegment,
                        name: AppRouteNames.workDetail,
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => dependencies.workDetail(
                          context,
                          state.pathParameters['vehicleId']!,
                          state.pathParameters['workId']!,
                          state.extra,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: subscriptionNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutePaths.subscription,
                name: AppRouteNames.subscription,
                builder: (context, state) => dependencies.subscription(context),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _authRedirect({
  required AuthNavigationStatus status,
  required String location,
}) {
  final isLogin = location == AppRoutePaths.login;
  final isRegistration = location == AppRoutePaths.registration;
  final isVerification = location == AppRoutePaths.emailVerification;
  final isSplash = location == AppRoutePaths.splash;
  final isPublicAuthRoute = isLogin || isRegistration;

  return switch (status) {
    AuthNavigationStatus.checking => isSplash ? null : AppRoutePaths.splash,
    AuthNavigationStatus.unauthenticated =>
      isPublicAuthRoute ? null : AppRoutePaths.login,
    AuthNavigationStatus.emailVerificationRequired =>
      isVerification ? null : AppRoutePaths.emailVerification,
    AuthNavigationStatus.authenticated =>
      (isSplash || isPublicAuthRoute || isVerification)
          ? AppRoutePaths.workshop
          : null,
  };
}
