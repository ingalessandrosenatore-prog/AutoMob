import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../vehicle/domain/entities/mechanic_summary.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import 'mechanic_3d_configuration.dart';
import 'mechanic_carousel.dart';

/// @brief Collega la scena ai dati del veicolo, senza accessi diretti ai servizi.
class HomeWorkshopCarousel extends StatelessWidget {
  const HomeWorkshopCarousel({super.key, this.isScrolling = false});

  final bool isScrolling;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DashboardBloc, DashboardState>(
    builder: (context, state) {
      if (state is! DashboardLoaded || state.vehicles.isEmpty) {
        return const SizedBox.shrink();
      }
      final vehicle = state.vehicles[state.index];
      final mascots = {
        for (final mascot in state.workshopMascotsByVehicleId[vehicle.id] ?? [])
          mascot.mechanicId: mascot,
      };
      return MechanicCarousel(
        isScrolling: isScrolling,
        configurations: [
          for (final mechanic in vehicle.mechanics)
            Mechanic3dConfiguration(
              id: mechanic.id,
              name: mechanic.businessName,
              pose: mascots[mechanic.id]?.pose ?? 'standing',
              tool: mascots[mechanic.id]?.prop ?? 'wrench',
              baseColor: _color(mascots[mechanic.id]?.baseColor, 0xFF252930),
              accentColor: _color(
                mascots[mechanic.id]?.accentColor,
                0xFFFF7926,
              ),
            ),
        ],
        selectedIndex:
            state.workshopIndexByVehicleId[vehicle.id] ??
            (vehicle.mechanics.isEmpty ? 0 : 1),
        onSelected: (index) => context.read<DashboardBloc>().add(
          WorkshopPageChanged(vehicleId: vehicle.id, index: index),
        ),
        onAdd: () => _open(context, vehicle.id),
        onOpen: (index) =>
            _open(context, vehicle.id, vehicle.mechanics[index - 1]),
      );
    },
  );

  static int _color(String? hex, int fallback) => hex == null
      ? fallback
      : 0xFF000000 | int.parse(hex.substring(1), radix: 16);

  Future<void> _open(
    BuildContext context,
    String vehicleId, [
    MechanicSummary? mechanic,
  ]) async {
    final bloc = context.read<DashboardBloc>();
    final changed = await context.pushNamed<bool>(
      'mechanicDetails',
      extra: <String, dynamic>{'vehicleId': vehicleId, 'mechanic': mechanic},
    );
    if (changed == true && !bloc.isClosed) {
      bloc.add(DashboardRefreshRequested());
    }
  }
}
