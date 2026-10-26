import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/service_request_report.dart';

class ServiceRequestReportDetails extends StatelessWidget {
  const ServiceRequestReportDetails({required this.report, super.key});
  final ServiceRequestReport report;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.warningLights.isNotEmpty)
          AmWarningLights(
            lights: [
              for (final light in report.warningLights)
                AmWarningLightData(
                  code: light.code,
                  color: light.color,
                  flashing: light.flashing,
                ),
            ],
          ),
        if (report.onboardMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Computer di bordo: ${report.onboardMessage}'),
          ),
        if (report.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Anomalia: ${report.description}'),
          ),
      ],
    ),
  );
}
