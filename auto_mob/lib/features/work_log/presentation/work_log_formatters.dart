import '../domain/entities/work_log_row.dart';

String workLogTitle(WorkLogRow work) {
  return switch (work.type) {
    'tagliando' => 'Tagliando',
    'distribuzione' => 'Distribuzione',
    'revisione' => 'Revisione',
    'pneumatici_cambio' => 'Cambio gomme',
    'pneumatici_inversione' => 'Inversione gomme',
    'altro' => _customTitle(work.customName),
    _ => work.type,
  };
}

String _customTitle(String? value) {
  final name = value?.trim() ?? '';
  return name.isEmpty ? 'Altro' : name;
}

String formatWorkLogDate(DateTime date) {
  const months = [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}

String formatWorkLogKm(int km) => '${_groupThousands(km)} km';

String formatEuroCents(int cents) {
  final euros = cents ~/ 100;
  final decimals = (cents % 100).abs().toString().padLeft(2, '0');
  return '${_groupThousands(euros)},$decimals €';
}

String formatQuantity(double quantity) {
  if (quantity == quantity.roundToDouble()) return quantity.toInt().toString();
  return quantity
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _groupThousands(int value) {
  final negative = value < 0;
  final source = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < source.length; index++) {
    if (index > 0 && (source.length - index) % 3 == 0) buffer.write('.');
    buffer.write(source[index]);
  }
  return negative ? '-$buffer' : buffer.toString();
}
