import 'package:auto_mob_v1/features/vehicle/domain/entities/revision_interval.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcola gli intervalli a partire dalla data indicata', () {
    final today = DateTime(2026, 7, 16);

    expect(RevisionInterval.sixMonths.dateFrom(today), DateTime(2027, 1, 16));
    expect(RevisionInterval.oneYear.dateFrom(today), DateTime(2027, 7, 16));
    expect(RevisionInterval.twoYears.dateFrom(today), DateTime(2028, 7, 16));
    expect(RevisionInterval.fourYears.dateFrom(today), DateTime(2030, 7, 16));
  });

  test('limita il giorno quando il mese di destinazione e piu corto', () {
    final leapDay = DateTime(2024, 2, 29);

    expect(RevisionInterval.oneYear.dateFrom(leapDay), DateTime(2025, 2, 28));
  });
}
