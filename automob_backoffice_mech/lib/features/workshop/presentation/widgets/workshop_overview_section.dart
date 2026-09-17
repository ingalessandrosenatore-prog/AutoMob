import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workshop_overview.dart';
import '../bloc/workshop_overview_cubit.dart';
import 'workshop_metric_card.dart';

class WorkshopOverviewSection extends StatelessWidget {
  const WorkshopOverviewSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkshopOverviewCubit, WorkshopOverview>(
        builder: (context, overview) {
          final cards = [
            WorkshopMetricCard(
              icon: Icons.bar_chart_rounded,
              label: 'Fatturato',
              value: _euro(overview.revenue),
              trend: overview.revenueGrowth,
              trendIsPercentage: true,
            ),
            WorkshopMetricCard(
              icon: Icons.assignment_turned_in_outlined,
              label: 'Lavori eseguiti',
              value: '${overview.completedJobs}',
              trend: overview.jobsGrowth,
            ),
            WorkshopMetricCard(
              icon: Icons.schedule_rounded,
              label: 'Lavori disponibili',
              value: '${overview.availableJobs}',
              caption: 'in attesa di conferma',
            ),
            WorkshopMetricCard(
              icon: Icons.toll_rounded,
              label: 'Possibile fatturato',
              value: _euro(overview.potentialRevenue),
              caption: 'dai lavori disponibili',
            ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmInsetTabBar(
                compact: true,
                labels: const ['Giorno', 'Mensile', 'Anno'],
                selectedIndex: overview.period.index,
                onChanged: (index) => context
                    .read<WorkshopOverviewCubit>()
                    .selectPeriod(WorkshopPeriod.values[index]),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Keep long labels readable with accessibility text sizes.
                  final singleColumn =
                      constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  if (singleColumn) {
                    return Column(
                      children: [
                        for (final card in cards)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: card,
                          ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var row = 0; row < 2; row++)
                        Padding(
                          padding: EdgeInsets.only(bottom: row == 0 ? 10 : 0),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: cards[row * 2]),
                                const SizedBox(width: 10),
                                Expanded(child: cards[row * 2 + 1]),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      );

  String _euro(int value) =>
      '€ ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]}.')}';
}
