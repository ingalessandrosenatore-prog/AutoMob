import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_type.dart';

class WorkLogTypeSelectionGrid extends StatelessWidget {
  const WorkLogTypeSelectionGrid({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELEZIONA TIPO INTERVENTO:',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          key: const Key('work-log-type-selection-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _workTypes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final type = _workTypes[index];
            return _WorkTypeCard(
              key: ValueKey('work-log-type-card-${type.value.wireValue}'),
              type: type,
              selected: selectedType == type.value.wireValue,
              onTap: () => onChanged(type.value.wireValue),
            );
          },
        ),
      ],
    );
  }
}

class _WorkTypeCard extends StatelessWidget {
  const _WorkTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final _WorkTypeVisual type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final borderColor = selected
        ? colors.accent
        : colors.surfaceHighlight.withValues(alpha: 0.58);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.accent.withValues(alpha: 0.14)
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: selected ? 1.8 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: type.asset == null
                        ? Center(
                            child: HugeIcon(
                              icon:
                                  HugeIcons.strokeRoundedMoreHorizontalCircle02,
                              color: colors.textSecondary,
                              size: 45,
                              strokeWidth: 1.7,
                            ),
                          )
                        : Image.asset(
                            type.asset!,
                            package: 'automob_work_log',
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    type.value.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? colors.accent : colors.textPrimary,
                      fontSize: 12,
                      height: 1.05,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTick02,
                      color: colors.onMedia,
                      size: 16,
                      strokeWidth: 2.8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _WorkTypeVisual = ({WorkLogType value, String? asset});

const _workTypes = <_WorkTypeVisual>[
  (value: WorkLogType.tagliando, asset: 'assets/images/car_check.png'),
  (value: WorkLogType.distribution, asset: 'assets/images/motor_check.png'),
  (value: WorkLogType.tireChange, asset: 'assets/images/gomme_check.png'),
  (value: WorkLogType.revision, asset: 'assets/images/car_check.png'),
  (value: WorkLogType.tireRotation, asset: 'assets/images/gomme_check.png'),
  (value: WorkLogType.engine, asset: 'assets/images/motor_check.png'),
  (value: WorkLogType.brakes, asset: 'assets/images/brakes_check.png'),
  (value: WorkLogType.chassis, asset: 'assets/images/chassis_check.png'),
  (
    value: WorkLogType.electronics,
    asset: 'assets/images/electronics_check.png',
  ),
  (value: WorkLogType.battery, asset: 'assets/images/electronics_check.png'),
  (value: WorkLogType.gearbox, asset: 'assets/images/gearbox_check.png'),
  (value: WorkLogType.other, asset: null),
];
