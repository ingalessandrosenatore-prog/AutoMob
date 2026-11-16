import 'package:common_ui_widget/common_ui_widget.dart';

import '../../../../core/widgets/mechanic_vehicle_card.dart';
import '../../domain/entities/workshop_catalog.dart';

MechanicVehicleCardData mapWorkshopVehicleToCardData(
  WorkshopVehicle vehicle,
) => MechanicVehicleCardData(
  id: vehicle.id,
  name: vehicle.displayName,
  plate: vehicle.plate,
  year: vehicle.year,
  kilometers: vehicle.kmCurrent,
  estimatedRevenueEuro: vehicle.estimatedRevenueEuro,
  status: vehicle.requiresMaintenance
      ? MechanicVehicleStatus.attention
      : MechanicVehicleStatus.connected,
  warningLights: [
    for (final light in vehicle.warningLights)
      AmWarningLightData(
        code: light.code,
        color: light.color,
        flashing: light.flashing,
      ),
  ],
  mandatoryWorks: [
    for (final work in vehicle.mandatoryWorks)
      MechanicMandatoryWorkItemData(
        title: work.title,
        subtitle:
            'Scadenza ${_formatKm(work.dueKm)} km · ${_formatKm(work.currentKm)} km attuali',
      ),
  ],
  userProblems: [
    for (final problem in vehicle.userProblems)
      MechanicUserProblemItemData(
        id: problem.id,
        description: problem.description,
        onboardMessage: problem.onboardMessage,
        headerLabel: _formatProblemHeader(
          problem.registeredAt,
          problem.reportedKm,
        ),
        warningLights: [
          for (final light in problem.warningLights)
            AmWarningLightData(
              code: light.code,
              color: light.color,
              flashing: light.flashing,
              onboardMessage: problem.onboardMessage,
              description: problem.description,
            ),
        ],
      ),
  ],
);

String _formatProblemHeader(DateTime? date, int? reportedKm) {
  final kmText = reportedKm == null
      ? 'km non rilevati'
      : '${_formatKm(reportedKm)} km';
  if (date == null) return kmText;
  const months = [
    'GEN',
    'FEB',
    'MAR',
    'APR',
    'MAG',
    'GIU',
    'LUG',
    'AGO',
    'SET',
    'OTT',
    'NOV',
    'DIC',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}  ·  $kmText';
}

String _formatKm(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (match) => '${match[1]}.',
);
