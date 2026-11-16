import 'package:common_ui_widget/common_ui_widget.dart';

class MechanicMandatoryWorkItemData {
  const MechanicMandatoryWorkItemData({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class MechanicUserProblemItemData {
  const MechanicUserProblemItemData({
    required this.id,
    required this.description,
    this.onboardMessage = '',
    this.headerLabel = '',
    this.warningLights = const [],
  });

  final String id;
  final String description;
  final String onboardMessage;
  final String headerLabel;
  final List<AmWarningLightData> warningLights;
}
