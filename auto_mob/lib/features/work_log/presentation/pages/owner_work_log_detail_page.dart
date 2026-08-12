import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../../../core/config/performance_flags.dart';

import '../../domain/entities/work_log_part.dart' as owner;
import '../../domain/entities/work_log_row.dart';

/// Cornice AutoMob del dettaglio; i contenuti sono nel package condiviso.
class OwnerWorkLogDetailPage extends StatelessWidget {
  OwnerWorkLogDetailPage({required WorkLogRow work, super.key})
    : entry = work.toSharedEntry();

  const OwnerWorkLogDetailPage.shared({required this.entry, super.key});

  final WorkLogEntry entry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AmThemeColors.of(context).background,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: 72,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: _DetailBackButton(onPressed: () => context.pop()),
      ),
      title: Text(
        'DETTAGLIO INTERVENTO',
        style: TextStyle(
          color: AmThemeColors.of(context).textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    ),
    body: WorkLogDetailBody(entry: entry),
  );
}

class _DetailBackButton extends StatelessWidget {
  const _DetailBackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final button = AmSoftButton(
      width: 48,
      height: 48,
      color: colors.surface.withValues(alpha: 0.2),
      iconColor: colors.textPrimary,
      icon: HugeIcons.strokeRoundedArrowLeft01,
      onPressed: onPressed,
    );
    return kHeavyEffects
        ? OCLiquidGlassGroup(
            settings: const OCLiquidGlassSettings(
              refractStrength: -0.13,
              blurRadiusPx: 1,
              specStrength: 2,
              specWidth: 0.5,
              specAngle: 145,
              blendPx: 20,
              specPower: 10,
            ),
            child: button,
          )
        : button;
  }
}

extension on WorkLogRow {
  WorkLogEntry toSharedEntry() => WorkLogEntry(
    id: id,
    vehicleId: '',
    type: type,
    serviceKm: serviceKm,
    serviceDate: serviceDate,
    customName: customName,
    notes: notes,
    hasWorkshop: hasWorkshop,
    workshopName: workshopName,
    parts: parts.map(_toSharedPart).toList(growable: false),
  );
}

WorkLogPart _toSharedPart(owner.WorkLogPart part) => WorkLogPart(
  partId: part.partId,
  name: part.name,
  quantity: part.quantity,
  unitPriceCents: part.unitPriceCents,
  notes: part.notes,
);
