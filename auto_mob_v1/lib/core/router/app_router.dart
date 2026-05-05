import 'package:auto_mob_v1/features/dashboard/presentation/page/HomeView.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/page/SplashScreen.dart';
import '../../features/auth/presentation/page/LoginView.dart';
import '../../features/auth/presentation/page/RegistrationView.dart';
import '../../features/vehicle/presentation/widget/PopUpAddVeicle.dart';
import '../../features/work_log/presentation/widget/FunctionalPopUp.dart';
import '../types/EnumPopUp.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/registration',
        name: 'registration',
        builder: (context, state) => const RegistrationView(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
       builder:  (context , state ) =>const HomeView(),
      ),

      GoRoute(path: '/addVeichle',
      name: 'aggiungi_veicolo',
      pageBuilder: (context,state){
       return BottomSheetPage();
          },
      ),


      GoRoute(path: '/addFunctional',
        name: 'aggiungi_Funzione',
        pageBuilder: (context, state) {
          final typeEnum = state.extra as EnumPopUp;
          return BottomSheetPageFunc(type:typeEnum);
        },
      ),

    ],
  );
}

extension AppRouterExtension on BuildContext {
  void goToLogin() => go('/login');
  void goToRegistration() => go('/registration');
  void goToHome(String userId) => go('/home/$userId');
}
