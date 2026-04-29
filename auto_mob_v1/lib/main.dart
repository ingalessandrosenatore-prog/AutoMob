import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'features/auth/presentation/Bloc/authBloc.dart';
import 'features/vehicle/presentation/provider/add_vehicle_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await di.init();
  runApp(const AutoMobApp());
}

class AutoMobApp extends StatelessWidget {
  const AutoMobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: di.sl<AuthBloc>()),
        // Altri BLoC saranno aggiunti qui quando implementeremo le altre feature
        // BlocProvider<DashboardBloc>(...),
        BlocProvider<AddVehicleBloc>.value(value: di.sl<AddVehicleBloc>()),
        // BlocProvider<WorkLogBloc>(...),
      ],
      child: MaterialApp.router(
        title: 'AutoMob',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}