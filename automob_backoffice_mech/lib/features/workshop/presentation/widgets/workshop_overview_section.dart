import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workshop_overview.dart';
import '../bloc/workshop_overview_cubit.dart';
import '../bloc/workshop_overview_state.dart';
import 'workshop_gear_period_selector.dart';
import 'workshop_kpi_gauge.dart';

class WorkshopOverviewSection extends StatelessWidget {
  const WorkshopOverviewSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkshopOverviewCubit, WorkshopOverviewState>(
        builder: (context, state) => switch (state) {
          WorkshopOverviewLoading() => const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
          WorkshopOverviewFailure() => SizedBox(
            height: 150,
            child: Center(
              child: TextButton.icon(
                onPressed: context.read<WorkshopOverviewCubit>().load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Riprova KPI'),
              ),
            ),
          ),
          WorkshopOverviewReady() => _WorkshopOverviewContent(state: state),
        },
      );
}

class _WorkshopOverviewContent extends StatelessWidget {
  const _WorkshopOverviewContent({required this.state});

  final WorkshopOverviewReady state;

  @override
  Widget build(BuildContext context) {
    final overview = state.overview;
    final gauges = [
      WorkshopKpiGauge(
        label: 'Fatturato',
        value: overview.revenueCents,
        maximum: state.catalog.revenueMaximumFor(state.period),
        valueFormatter: _euroFromCents,
      ),
      WorkshopKpiGauge(
        label: 'Lavori eseguiti',
        value: overview.completedJobs,
        maximum: overview.completedJobs + overview.availableJobs,
        valueFormatter: (value) => '${value.round()}',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Keep long labels readable with accessibility text sizes.
            final singleColumn =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 21;
            if (singleColumn) {
              return Column(
                children: [
                  for (var index = 0; index < gauges.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == gauges.length - 1 ? 0 : 10,
                      ),
                      child: gauges[index],
                    ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: gauges[0]),
                const SizedBox(width: 10),
                Expanded(child: gauges[1]),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        WorkshopGearPeriodSelector(
          labels: const ['Giorno', 'Mensile', 'Annuale'],
          selectedIndex: state.period.index,
          onChanged: (index) => context
              .read<WorkshopOverviewCubit>()
              .selectPeriod(WorkshopPeriod.values[index]),
        ),
      ],
    );
  }

  String _euroFromCents(num value) {
    final euros = value.round() ~/ 100;
    return '€ ${euros.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]}.')}';
  }
}
