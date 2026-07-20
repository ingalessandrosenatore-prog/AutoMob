import 'package:auto_mob_v1/features/work_log/domain/entities/work_log_row.dart';
import 'package:auto_mob_v1/features/work_log/presentation/work_log_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatta titolo, data, km, quantità e importi italiani', () {
    final work = WorkLogRow(
      id: 'w1',
      type: 'altro',
      customName: ' Lucidatura ',
      serviceKm: 42000,
      serviceDate: DateTime(2026, 7, 20),
      hasWorkshop: false,
    );

    expect(workLogTitle(work), 'Lucidatura');
    expect(formatWorkLogDate(work.serviceDate), '20 Lug 2026');
    expect(formatWorkLogKm(work.serviceKm), '42.000 km');
    expect(formatQuantity(1.5), '1.5');
    expect(formatEuroCents(123456), '1.234,56 €');
  });
}
