import 'package:auto_mob_v1/features/work_log/data/models/work_log_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkLogRowModel.fromJson', () {
    test('mappa officina e tutte le parti dello specifico item', () {
      final model = WorkLogRowModel.fromJson(const {
        'id': 'item-1',
        'type': 'tagliando',
        'custom_name': null,
        'service_km': 42000,
        'service_date': '2026-07-20',
        'notes': 'Nota completa',
        'maintenance_records': {
          'vehicle_id': 'vehicle-1',
          'mechanic_id': 'mechanic-1',
          'mechanics': {'business_name': ' Officina Ferrari '},
        },
        'maintenance_item_parts': [
          {
            'part_id': 15,
            'quantity': 2,
            'unit_price': 12.345,
            'notes': 'Sintetico',
            'parts': {'name': 'Olio motore'},
          },
          {
            'part_id': 16,
            'quantity': '1.5',
            'unit_price': '8.40',
            'notes': null,
            'parts': {'name': 'Filtro olio'},
          },
        ],
      });

      expect(model.hasWorkshop, isTrue);
      expect(model.workshopName, 'Officina Ferrari');
      expect(model.parts, hasLength(2));
      expect(model.parts.first.name, 'Olio motore');
      expect(model.parts.first.unitPriceCents, 1235);
      expect(model.parts.first.subtotalCents, 2470);
      expect(model.parts.last.quantity, 1.5);
      expect(model.parts.last.unitPriceCents, 840);
      expect(model.partsTotalCents, 3730);
    });

    test('accetta item senza officina, parti o prezzi', () {
      final model = WorkLogRowModel.fromJson(const {
        'id': 'item-2',
        'type': 'revisione',
        'service_km': 50000,
        'service_date': '2026-07-20',
        'notes': null,
        'maintenance_records': {
          'vehicle_id': 'vehicle-1',
          'mechanic_id': null,
          'mechanics': null,
        },
        'maintenance_item_parts': <Object?>[],
      });

      expect(model.hasWorkshop, isFalse);
      expect(model.workshopName, isNull);
      expect(model.parts, isEmpty);
      expect(model.partsTotalCents, 0);
    });
  });
}
