enum WorkLogType {
  tagliando('tagliando', 'Tagliando'),
  distribution('distribuzione', 'Distribuzione'),
  tireChange('pneumatici_cambio', 'Cambio gomme'),
  revision('revisione', 'Revisione'),
  tireRotation('pneumatici_inversione', 'Inversione gomme'),
  engine('motore', 'Motore', allowsCustomName: true),
  brakes('freni', 'Freni', allowsCustomName: true),
  chassis('telaio', 'Telaio', allowsCustomName: true),
  electronics('elettronica', 'Elettronica', allowsCustomName: true),
  battery('batteria', 'Batteria', allowsCustomName: true),
  gearbox('cambio', 'Cambio', allowsCustomName: true),
  other('altro', 'Altro', allowsCustomName: true, requiresCustomName: true);

  const WorkLogType(
    this.wireValue,
    this.label, {
    this.allowsCustomName = false,
    this.requiresCustomName = false,
  });

  final String wireValue;
  final String label;
  final bool allowsCustomName;
  final bool requiresCustomName;

  static WorkLogType? tryFromWire(String value) {
    for (final type in values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}
