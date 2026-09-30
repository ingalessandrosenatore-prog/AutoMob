import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_type.dart';

List<List<dynamic>> workLogTypeIcon(String wireValue) =>
    switch (WorkLogType.tryFromWire(wireValue)) {
      WorkLogType.tireChange ||
      WorkLogType.tireRotation => HugeIcons.strokeRoundedTire,
      WorkLogType.engine => HugeIcons.strokeRoundedEngine,
      WorkLogType.brakes => HugeIcons.strokeRoundedDisc,
      WorkLogType.chassis => HugeIcons.strokeRoundedSteering,
      WorkLogType.electronics => HugeIcons.strokeRoundedChip,
      WorkLogType.battery => HugeIcons.strokeRoundedAutomotiveBattery01,
      WorkLogType.gearbox => HugeIcons.strokeRoundedTransmission,
      WorkLogType.tagliando ||
      WorkLogType.distribution ||
      WorkLogType.revision ||
      WorkLogType.other ||
      null => HugeIcons.strokeRoundedTools,
    };
