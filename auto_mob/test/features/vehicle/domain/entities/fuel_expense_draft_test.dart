import 'package:auto_mob_v1/features/vehicle/domain/entities/fuel_expense_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte euro e litri con virgola in interi esatti', () {
    final draft = FuelExpenseDraft.tryParse(
      costEuros: '50,25',
      liters: '32,750',
    );

    expect(draft?.costCents, 5025);
    expect(draft?.litersMilli, 32750);
  });

  test('accetta entrambi i campi vuoti come rifornimento assente', () {
    expect(FuelExpenseDraft.tryParse(costEuros: '', liters: ''), isNull);
    expect(
      FuelExpenseDraft.hasPartialInput(costEuros: '', liters: ''),
      isFalse,
    );
  });

  test('rifiuta un solo campo compilato e valori non positivi', () {
    expect(
      FuelExpenseDraft.hasPartialInput(costEuros: '20', liters: ''),
      isTrue,
    );
    expect(FuelExpenseDraft.tryParse(costEuros: '0', liters: '10'), isNull);
  });
}
