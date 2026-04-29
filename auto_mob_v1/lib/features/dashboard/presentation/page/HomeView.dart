import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../Bloc/dashboardBloc.dart';
import '../Bloc/dashboardEvent.dart';
import '../Bloc/dashboardState.dart';
import '../widget/CardAuto.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) => GetIt.I<DashboardBloc>()..add(LoadDashboardData()),
      child: const _HomeViewBody(),
    );
  }
}

class _HomeViewBody extends StatelessWidget {
  const _HomeViewBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AmMainFab(
                    label: 'aggiungi',
                    color: Colors.orange,
                    icon: Icons.add,
                    onPressed: () => context.pushNamed('aggiungi_veicolo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading || state is DashboardInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is DashboardError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFFF453A)),
                        ),
                      ),
                    );
                  }
                  if (state is DashboardLoaded) {
                    final vehicles = state.vehicles;
                    return ListView.builder(
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        // TODO: in futuro gestire il tap → pagina dettaglio veicolo
                        // (per il placeholder il tap puo' invocare il wizard "aggiungi")
                        return CardAuto(
                          marca: v.brand,
                          modello: v.model,
                          kmTotali: v.isPlaceholder ? '—' : v.kmCurrent.toString(),
                          immaginePath: null, // TODO: collegare immagine veicolo
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AmMainFab(
        label: 'aggiorna',
        color: Colors.orange,
        icon: Icons.update,
        onPressed: () =>
            context.read<DashboardBloc>().add(LoadDashboardData()),
      ),
    );
  }
}
