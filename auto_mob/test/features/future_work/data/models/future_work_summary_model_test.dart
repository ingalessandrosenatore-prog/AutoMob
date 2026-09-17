import 'package:auto_mob_v1/features/future_work/data/models/future_work_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mappa descrizione e date della query dashboard', () {
    final model = FutureWorkSummaryModel.fromJson(const {
      'id': 'item-1',
      'record_id': 'record-1',
      'vehicle_id': 'vehicle-1',
      'description': 'Cambio pastiglie posteriori',
      'registered_at': '2026-09-17T10:30:00Z',
      'reminder_date': '2026-09-30',
    });

    expect(model.id, 'item-1');
    expect(model.recordId, 'record-1');
    expect(model.vehicleId, 'vehicle-1');
    expect(model.description, 'Cambio pastiglie posteriori');
    expect(model.registeredAt, DateTime.utc(2026, 9, 17, 10, 30));
    expect(model.reminderDate, DateTime(2026, 9, 30));
  });
}
