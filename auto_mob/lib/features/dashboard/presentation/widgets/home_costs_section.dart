import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/maintenance_cost_period.dart';

const _periodLabels = ['Giornaliero', 'Mensile', 'Annuale'];

class HomeCostsSection extends StatelessWidget {
  const HomeCostsSection({
    super.key,
    this.selectedPeriod = MaintenanceCostPeriod.monthly,
    this.maintenanceCostCents = 0,
    this.onPeriodChanged,
  });

  final MaintenanceCostPeriod selectedPeriod;
  final int maintenanceCostCents;
  final ValueChanged<MaintenanceCostPeriod>? onPeriodChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmInsetTabBar(
          compact: true,
          labels: _periodLabels,
          selectedIndex: selectedPeriod.index,
          onChanged: (index) =>
              onPeriodChanged?.call(MaintenanceCostPeriod.values[index]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CostCard(
                icon: Icons.handyman_outlined,
                label: 'Manutenzione',
                value: _formatEuro(maintenanceCostCents),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _CostCard(
                icon: Icons.local_gas_station_outlined,
                label: 'Carburante',
                value: '-',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _CostCard(
                icon: Icons.description_outlined,
                label: 'Documenti',
                value: '-',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _YearTimeline(),
      ],
    ),
  );
}

String _formatEuro(int cents) {
  final euros = cents ~/ 100;
  final decimals = (cents % 100).abs().toString().padLeft(2, '0');
  return '€ $euros,$decimals';
}

class _CostCard extends StatelessWidget {
  const _CostCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      height: 82,
      padding: const EdgeInsets.all(1.5),
      decoration: ShapeDecoration(
        gradient: colors.cardBorderGradient,
        shape: _shape(20),
        shadows: colors.cardShadows,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: _shape(19)),
        child: ColoredBox(
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: colors.accent, size: 20),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YearTimeline extends StatelessWidget {
  const _YearTimeline();

  static const _items = [
    (year: 2022, status: 'Scaduto', tone: _BadgeTone.danger),
    (year: 2023, status: 'Pagato', tone: _BadgeTone.paid),
    (year: 2024, status: 'Pagato', tone: _BadgeTone.paid),
    (year: 2025, status: 'Pagato', tone: _BadgeTone.paid),
    (year: 2026, status: 'In corso', tone: _BadgeTone.current),
    (year: 2027, status: null, tone: _BadgeTone.none),
    (year: 2028, status: null, tone: _BadgeTone.none),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('home-costs-year-timeline'),
    height: 98,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) => _YearCard(item: _items[index]),
    ),
  );
}

enum _BadgeTone { danger, paid, current, none }

class _YearCard extends StatelessWidget {
  const _YearCard({required this.item});

  final ({int year, String? status, _BadgeTone tone}) item;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final badgeColor = switch (item.tone) {
      _BadgeTone.danger => colors.danger,
      _BadgeTone.paid => colors.info,
      _BadgeTone.current => colors.accent,
      _BadgeTone.none => Colors.transparent,
    };
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 68,
          padding: const EdgeInsets.all(1.5),
          decoration: ShapeDecoration(
            gradient: colors.cardBorderGradient,
            shape: _shape(18),
            shadows: colors.cardShadows,
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: _shape(17)),
            child: ColoredBox(
              color: colors.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.car_repair_outlined,
                    color: colors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.year}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (item.status != null)
          Positioned(
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status!,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

SmoothRectangleBorder _shape(double radius) => SmoothRectangleBorder(
  borderRadius: SmoothBorderRadius(cornerRadius: radius, cornerSmoothing: 0.8),
);
