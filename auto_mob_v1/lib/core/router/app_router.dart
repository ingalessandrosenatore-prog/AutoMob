import 'package:auto_mob_v1/features/dashboard/presentation/page/HomeView.dart';
import 'package:auto_mob_v1/features/work_log/presentation/page/MidifyItem.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/page/SplashScreen.dart';
import '../../features/auth/presentation/page/LoginView.dart';
import '../../features/auth/presentation/page/RegistrationView.dart';
import '../../features/vehicle/presentation/widget/KmUpdatePopUp.dart';
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
          final extra = state.extra as Map<String, dynamic>;
          final typeEnum = extra['type'] as EnumPopUp;
          final id = extra['id'] as String;
          return BottomSheetPageFunc(type: typeEnum, idVeicolo: id);
        },
      ),
      GoRoute(
        path: '/parts',
        name: 'parts',
        builder:  (context , state ) => Midifyitem(),
      ),

      GoRoute(path: '/updatePopUp',
        name: 'updateKm',
        pageBuilder: (context ,state){
          final extra = state.extra as Map<String, dynamic>?;
          final currentKm = (extra?['currentKm'] as String?) ?? '0';

          return KmUpdatePopUp(currentKm: currentKm);
        },

      ),

    ],
  );
}

