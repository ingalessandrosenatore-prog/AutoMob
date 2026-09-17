import '../../domain/entities/service_request.dart';

/// Fixture dimostrative isolate, sostituibili con una sorgente remota.
class ServiceRequestMockDataSource {
  const ServiceRequestMockDataSource();

  Future<List<ServiceRequest>> getRequests() async => [
    ServiceRequest(
      id: 'request-1',
      vehicleModel: 'Alfa Romeo Mito',
      plate: 'DT 512 FD',
      issues: ['Cambio pastiglie posteriori', 'Controllo dischi'],
      estimatedCost: 180,
      registeredAt: DateTime(2026, 9, 1),
      reminderDate: DateTime(2026, 9, 30),
    ),
    ServiceRequest(
      id: 'request-2',
      vehicleModel: 'Volkswagen Golf',
      plate: 'GA 284 LX',
      issues: [
        'Rumore durante la sterzata',
        'Spia pressione pneumatici',
        'Controllo convergenza',
      ],
      estimatedCost: 240,
      registeredAt: DateTime(2026, 9, 2),
      reminderDate: DateTime(2026, 10, 2),
    ),
    ServiceRequest(
      id: 'request-3',
      vehicleModel: 'Fiat 500X',
      plate: 'FM 903 NK',
      issues: ['Tagliando periodico', 'Sostituzione filtro abitacolo'],
      estimatedCost: 150,
      registeredAt: DateTime(2026, 9, 3),
      reminderDate: DateTime(2026, 10, 3),
    ),
  ];
}
