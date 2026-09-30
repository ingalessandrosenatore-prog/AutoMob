import 'package:equatable/equatable.dart';

class FuelCostAverages extends Equatable {
  const FuelCostAverages({
    required this.dailyCents,
    required this.monthlyCents,
    required this.annualCents,
  });

  static const zero = FuelCostAverages(
    dailyCents: 0,
    monthlyCents: 0,
    annualCents: 0,
  );

  final int dailyCents;
  final int monthlyCents;
  final int annualCents;

  @override
  List<Object> get props => [dailyCents, monthlyCents, annualCents];
}
