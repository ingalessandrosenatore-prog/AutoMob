import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workshop_overview.dart';
import '../bloc/workshop_overview_cubit.dart';
import 'workshop_gear_period_selector.dart';
import 'workshop_kpi_gauge.dart';

class WorkshopOverviewSection extends StatelessWidget {
  const WorkshopOverviewSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkshopOverviewCubit, WorkshopOverview>(
        builder: (context, overview) {
          final gauges = [
            WorkshopKpiGauge(
              label: 'Fatturato',
              value: overview.revenue,
              maximum: overview.revenue + overview.potentialRevenue,
              valueFormatter: _euro,
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
                selectedIndex: overview.period.index,
                onChanged: (index) => context
                    .read<WorkshopOverviewCubit>()
                    .selectPeriod(WorkshopPeriod.values[index]),
              ),
            ],
          );
        },
      );

  String _euro(num value) =>
      '€ ${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]}.')}';
}
