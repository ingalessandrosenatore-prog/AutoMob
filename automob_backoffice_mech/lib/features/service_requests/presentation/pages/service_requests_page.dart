import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/mechanic_shell_metrics.dart';
import '../../../../core/widgets/mechanic_search_bar.dart';
import '../../domain/entities/service_request.dart';
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
            ServiceRequestsReady(:final requests, :final query) =>
              _ServiceRequestsContent(
                requests: requests,
                query: query,
                shellBottom: shellBottom,
              ),
          },
        ),
      ),
    );
  }
}

class _ServiceRequestsContent extends StatelessWidget {
  const _ServiceRequestsContent({
    required this.requests,
    required this.query,
    required this.shellBottom,
  });

  final List<ServiceRequest> requests;
  final String query;
  final double shellBottom;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final restingSearchBottom =
        shellBottom +
        MechanicShellMetrics.navigationHeight +
        MechanicShellMetrics.searchNavigationGap;
    final searchBottom = keyboardInset > 0
        ? math.max(restingSearchBottom, keyboardInset + 12)
        : restingSearchBottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Stack(
          children: [
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: context.read<ServiceRequestsCubit>().refresh,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              query.isEmpty
                                  ? 'Nessuna segnalazione aperta'
                                  : 'Nessuna richiesta trovata',
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height:
                            searchBottom +
                            MechanicShellMetrics.searchHeight +
                            16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              key: const ValueKey('service-requests-search-row'),
              left: MechanicShellMetrics.horizontalMargin,
              right: MechanicShellMetrics.horizontalMargin,
              bottom: searchBottom,
              child: MechanicSearchBar(
                hintText: 'Cerca veicolo, targa o problema...',
                onChanged: context.read<ServiceRequestsCubit>().search,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
