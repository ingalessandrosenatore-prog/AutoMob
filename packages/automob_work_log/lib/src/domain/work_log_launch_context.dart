import 'package:equatable/equatable.dart';

/// Dati che l'app chiamante passa al flusso Work Log.
/// Il package non ricava mai questi valori da GetIt, router o storage locale.
class WorkLogLaunchContext extends Equatable {
  const WorkLogLaunchContext({
    required this.vehicleId,
    required this.vehicleName,
    required this.currentKm,
    this.initialWorkType = 'altro',
  });

  final String vehicleId;
  final String vehicleName;
  final int currentKm;
  final String initialWorkType;

  @override
  List<Object?> get props => [
    vehicleId,
    vehicleName,
    currentKm,
    initialWorkType,
  ];
}

/// Risultato ritornato dal wizard al router chiamante dopo un salvataggio.
class WorkLogSaveResult extends Equatable {
  const WorkLogSaveResult({required this.vehicleId, required this.serviceKm});

  final String vehicleId;
  final int serviceKm;

  @override
  List<Object?> get props => [vehicleId, serviceKm];
}
