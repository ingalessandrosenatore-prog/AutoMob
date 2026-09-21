import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/maintenance_cost_period.dart';

const _periodLabels = ['Giornaliero', 'Mensile', 'Annuale'];

class HomeCostsSection extends StatelessWidget {
  const HomeCostsSection({
    super.key,
    this.selectedPeriod = MaintenanceCostPeriod.monthly,
    this.maintenanceCostCents = 0,
    this.onPeriodChanged,
    this.now,
  });

  final MaintenanceCostPeriod selectedPeriod;
  final int maintenanceCostCents;
  final ValueChanged<MaintenanceCostPeriod>? onPeriodChanged;

  /// Iniettabile per rendere deterministici i test del progresso temporale.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final progress = _periodProgress(selectedPeriod, now ?? DateTime.now());
    final gauges = [
      (
        icon: Icons.handyman_outlined,
        label: 'Manutenzione',
        value: maintenanceCostCents > 0 ? maintenanceCostCents : null,
      ),
      (
        icon: Icons.local_gas_station_outlined,
        label: 'Carburante',
        value: null,
      ),
      (icon: Icons.description_outlined, label: 'Documenti', value: null),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < gauges.length; index++) ...[
                if (index > 0) const SizedBox(width: 4),
                Expanded(
                  child: AmKpiGauge(
                    key: ValueKey('home_cost_gauge_$index'),
                    icon: gauges[index].icon,
                    semanticLabel: gauges[index].label,
                    value: gauges[index].value,
                    progress: progress,
                    compact: true,
                    valueFormatter: _formatEuro,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          AmGearPeriodSelector(
            labels: _periodLabels,
            selectedIndex: selectedPeriod.index,
            onChanged: (index) =>
                onPeriodChanged?.call(MaintenanceCostPeriod.values[index]),
            semanticLabel: 'Periodo costi AutoMob',
          ),
        ],
      ),
    );
  }
}

double _periodProgress(MaintenanceCostPeriod period, DateTime now) =>
    switch (period) {
      MaintenanceCostPeriod.daily =>
        (now.hour * 3600 +
                now.minute * 60 +
                now.second +
                now.millisecond / 1000) /
            Duration.secondsPerDay,
      MaintenanceCostPeriod.monthly =>
        now.day / DateTime(now.year, now.month + 1, 0).day,
      MaintenanceCostPeriod.annual => now.month / 12,
    };

String _formatEuro(num cents) {
  final roundedCents = cents.round();
  final euros = roundedCents ~/ 100;
  final decimals = (roundedCents % 100).abs().toString().padLeft(2, '0');
  return '€ $euros,$decimals';
}
