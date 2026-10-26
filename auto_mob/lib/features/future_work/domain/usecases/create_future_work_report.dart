import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/future_work_report.dart';
import '../entities/warning_light_observation.dart';
import '../repositories/future_work_repository.dart';

class CreateFutureWorkReport {
  CreateFutureWorkReport(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final FutureWorkRepository repository;
  final DateTime Function() _now;

  Future<Either<Failure, FutureWorkReport>> call({
    required String vehicleId,
    required String description,
    String onboardMessage = '',
    List<WarningLightObservation> warningLights = const [],
    required DateTime reminderDate,
  }) {
    final normalizedDescription = description.trim();
    if (vehicleId.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Veicolo non valido.')));
    }
    if ((normalizedDescription.isEmpty &&
            onboardMessage.trim().isEmpty &&
            warningLights.isEmpty) ||
        normalizedDescription.length > 1000 ||
        onboardMessage.trim().length > 1000) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Descrivi il problema usando massimo 1000 caratteri.',
          ),
        ),
      );
    }

    if (warningLights.any(
          (light) =>
              !RegExp(
                r'^(S(0[1-9]|[1-3][0-9]|40)|STOP|SERVICE|OTHER)$',
              ).hasMatch(light.code) ||
              !{
                'red',
                'amber',
                'green',
                'blue',
                'white',
                'unknown',
              }.contains(light.color),
        ) ||
        warningLights.toSet().length != warningLights.length) {
      return Future.value(const Left(ValidationFailure('Spie non valide.')));
    }
    final today = _dateOnly(_now());
    final deadline = _dateOnly(reminderDate);
    if (deadline.isBefore(today)) {
      return Future.value(
        const Left(
          ValidationFailure('La data di richiamo non può essere nel passato.'),
        ),
      );
    }

    return repository.createReport(
      vehicleId: vehicleId,
      description: normalizedDescription,
      onboardMessage: onboardMessage.trim(),
      warningLights: List.unmodifiable(warningLights),
      reminderDate: deadline,
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
