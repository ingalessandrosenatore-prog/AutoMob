import 'package:automob_work_log/automob_work_log.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/work_log_part.dart' as owner;
import '../../domain/entities/work_log_row.dart';

/// Cornice AutoMob del dettaglio; i contenuti sono nel package condiviso.
class OwnerWorkLogDetailPage extends StatelessWidget {
  OwnerWorkLogDetailPage({required WorkLogRow work, super.key})
    : entry = work.toSharedEntry(),
      currentKm = null,
      onAddPressed = null;

  const OwnerWorkLogDetailPage.shared({
    required this.entry,
    this.currentKm,
    this.onAddPressed,
    super.key,
  });

  final WorkLogEntry entry;
  final int? currentKm;
  final ValueChanged<WorkLogType>? onAddPressed;

  @override
  Widget build(BuildContext context) => WorkLogDetailPage(
    entry: entry,
    currentKm: currentKm,
    onBackPressed: context.pop,
    onAddPressed: onAddPressed,
  );
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
