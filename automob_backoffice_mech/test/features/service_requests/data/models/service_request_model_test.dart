import 'package:automob_backoffice_mech/features/service_requests/data/models/service_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'keeps anomaly, onboard message and warning observations independent',
    () {
      final request = ServiceRequestModel.fromJson({
        'id': 'v1',
        'vehicle_model': 'Fiat Panda',
        'plate': 'AB123CD',
        'registered_at': '2026-10-26',
        'reminder_date': '2026-10-27',
        'issues': ['Rumore frenando'],
        'reports': [
          {
            'record_id': 'r1',
            'description': 'Rumore frenando',
            'onboard_message': 'Controllare ABS',
            'warning_lights': [
              {'code': 'S03', 'color': 'amber', 'flashing': true},
            ],
          },
        ],
      });
      expect(request.reports.single.description, 'Rumore frenando');
      expect(request.reports.single.onboardMessage, 'Controllare ABS');
      expect(request.reports.single.warningLights.single.code, 'S03');
      expect(request.reports.single.warningLights.single.color, 'amber');
      expect(request.reports.single.warningLights.single.flashing, isTrue);
    },
  );
  test('legacy reports remain readable', () {
    final request = ServiceRequestModel.fromJson({
      'id': 'v1',
      'vehicle_model': 'Fiat Panda',
      'plate': 'AB123CD',
      'registered_at': '2026-10-26',
      'reminder_date': '2026-10-27',
      'issues': ['Freni'],
    });
    expect(request.reports, isEmpty);
    expect(request.issues, ['Freni']);
  });
}
