import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/router/mechanic_shell_metrics.dart';
import '../bloc/service_requests_cubit.dart';
import '../widgets/service_request_card.dart';

class ServiceRequestsPage extends StatelessWidget {
  const ServiceRequestsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final shellBottom = MechanicShellGeometry.of(context).controlsBottom;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ServiceRequestsCubit, ServiceRequestsState>(
          builder: (context, state) => switch (state) {
            ServiceRequestsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ServiceRequestsFailure() => RefreshIndicator(
              onRefresh: context.read<ServiceRequestsCubit>().refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: Center(
                      child: Text(
                        'Richieste non disponibili',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ServiceRequestsReady(:final requests) => RefreshIndicator(
              onRefresh: context.read<ServiceRequestsCubit>().refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Richieste di intervento',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${requests.length} segnalazioni aperte',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                    sliver: SliverList.separated(
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return ServiceRequestCard(
                          key: ValueKey(request.id),
                          request: request,
                          onExecute: () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Apertura intervento per ${request.vehicleModel}',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            ),
                        );
                      },
                    ),
                  ),
                  if (requests.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Nessuna segnalazione aperta'),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          shellBottom +
                          MechanicShellMetrics.navigationHeight +
                          24,
                    ),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}
