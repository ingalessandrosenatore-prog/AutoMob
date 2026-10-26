import '../../domain/entities/warning_light_observation.dart';

List<WarningLightObservation> parseWarningLights(Object? value) => value is List
    ? value
          .map((item) {
            final json = Map<String, dynamic>.from(item as Map);
            return WarningLightObservation(
              code: json['code'] as String,
              color: json['color'] as String,
              flashing: json['flashing'] as bool? ?? false,
            );
          })
          .toList(growable: false)
    : const [];
