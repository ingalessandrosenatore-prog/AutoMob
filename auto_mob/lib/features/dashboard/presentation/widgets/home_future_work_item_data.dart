import '../../../future_work/domain/entities/future_work_summary.dart';
import '../../../future_work/domain/entities/warning_light_observation.dart';

class HomeFutureWorkItemData {
  const HomeFutureWorkItemData({
    required this.title,
    this.recordId,
    this.onboardMessage = '',
    this.kmLabel = 'km non rilevati',
    this.warningLights = const [],
    required this.registeredDateLabel,
  });

  final String? recordId;
  final String onboardMessage;
  final String kmLabel;
  final List<WarningLightObservation> warningLights;
  final String title;
  final String registeredDateLabel;

  factory HomeFutureWorkItemData.fromSummary(
    FutureWorkSummary summary,
  ) => HomeFutureWorkItemData(
    title: summary.message.isEmpty ? 'Spie segnalate' : summary.message,
    kmLabel: summary.reportedKm == null
        ? 'km non rilevati'
        : '${summary.reportedKm.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]}.')} km',
    recordId: summary.recordId,
    onboardMessage: summary.onboardMessage,
    warningLights: summary.warningLights,
    registeredDateLabel: _formatDate(summary.registeredAt),
  );
}

String _formatDate(DateTime value) {
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
  final day = value.day.toString().padLeft(2, '0');
  return '$day ${months[value.month - 1]} ${value.year}';
}
