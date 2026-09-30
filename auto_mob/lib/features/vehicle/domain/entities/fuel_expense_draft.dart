import 'package:equatable/equatable.dart';

class FuelExpenseDraft extends Equatable {
  const FuelExpenseDraft({required this.costCents, required this.litersMilli});

  final int costCents;
  final int litersMilli;

  static FuelExpenseDraft? tryParse({
    required String costEuros,
    required String liters,
  }) {
    final normalizedCost = costEuros.trim();
    final normalizedLiters = liters.trim();
    if (normalizedCost.isEmpty || normalizedLiters.isEmpty) return null;

    final costCents = _parseScaled(normalizedCost, decimalPlaces: 2);
    final litersMilli = _parseScaled(normalizedLiters, decimalPlaces: 3);
    if (costCents == null || litersMilli == null) return null;
    if (costCents <= 0 || litersMilli <= 0) return null;
    return FuelExpenseDraft(costCents: costCents, litersMilli: litersMilli);
  }

  static bool hasPartialInput({
    required String costEuros,
    required String liters,
  }) {
    return costEuros.trim().isEmpty != liters.trim().isEmpty;
  }

  static int? _parseScaled(String value, {required int decimalPlaces}) {
    final normalized = value.replaceAll(',', '.');
    final pattern = RegExp('^\\d+(?:\\.\\d{1,$decimalPlaces})?\$');
    if (!pattern.hasMatch(normalized)) return null;

    final parts = normalized.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(decimalPlaces, '0'));
    final scale = switch (decimalPlaces) {
      2 => 100,
      3 => 1000,
      _ => throw ArgumentError.value(decimalPlaces, 'decimalPlaces'),
    };
    return whole * scale + fraction;
  }

  @override
  List<Object> get props => [costCents, litersMilli];
}
