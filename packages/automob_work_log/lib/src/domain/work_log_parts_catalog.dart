import 'work_log_type.dart';

enum WorkLogPartCategory {
  engine('motore'),
  vehicle('veicolo'),
  tires('gomme'),
  chassis('telaio'),
  electronics('elettronica'),
  brakes('freni'),
  gearbox('cambio');

  const WorkLogPartCategory(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
    WorkLogPartCategory.engine => 'Motore',
    WorkLogPartCategory.vehicle => 'Veicolo',
    WorkLogPartCategory.tires => 'Gomme',
    WorkLogPartCategory.chassis => 'Telaio',
    WorkLogPartCategory.electronics => 'Elettronica',
    WorkLogPartCategory.brakes => 'Freni',
    WorkLogPartCategory.gearbox => 'Cambio',
  };

  static WorkLogPartCategory? tryFromWire(String? value) {
    for (final category in values) {
      if (category.wireValue == value) return category;
    }
    return null;
  }
}

WorkLogPartCategory workLogPartCategoryForType(WorkLogType? type) =>
    switch (type) {
      WorkLogType.distribution ||
      WorkLogType.engine => WorkLogPartCategory.engine,
      WorkLogType.tireChange ||
      WorkLogType.tireRotation => WorkLogPartCategory.tires,
      WorkLogType.brakes => WorkLogPartCategory.brakes,
      WorkLogType.chassis => WorkLogPartCategory.chassis,
      WorkLogType.electronics ||
      WorkLogType.battery => WorkLogPartCategory.electronics,
      WorkLogType.gearbox => WorkLogPartCategory.gearbox,
      WorkLogType.tagliando ||
      WorkLogType.revision ||
      WorkLogType.other ||
      null => WorkLogPartCategory.vehicle,
    };

class WorkLogPartCatalogEntry {
  const WorkLogPartCatalogEntry({required this.name, required this.category});

  final String name;
  final WorkLogPartCategory category;
}

/// Vista compatibile `id -> nome` del catalogo ricambi.
///
/// È un mirror della tabella `parts` del DB (colonne `id bigint`, `name text`):
/// gli `id` qui DEVONO combaciare con quelli del DB (1-95). Se aggiungi/modifichi
/// una parte, fallo in UN SOLO posto: prima nel DB (`INSERT INTO parts ...`), poi
/// allinea questa mappa. Niente più copie sparse nei widget.
///
/// Usata da: PartsPickerBody (chip selezionabili) e MidifyItem (nome card).
const Map<int, String> kPartsCatalog = {
  1: 'Motore',
  2: 'Pistoni',
  3: 'Bielle',
  4: 'Albero motore',
  5: 'Testata',
  6: 'Guarnizione testata',
  7: 'Candele',
  8: 'Candelette',
  9: 'Cinghia distribuzione',
  10: 'Catena distribuzione',
  11: 'Tendicinghia',
  12: 'Pompa olio',
  13: 'Coppa olio',
  14: 'Valvole',
  15: 'Filtro olio',
  16: 'Filtro aria',
  17: 'Filtro abitacolo',
  18: 'Filtro carburante',
  19: 'Filtro gasolio',
  20: 'Pastiglie freno anteriori',
  21: 'Pastiglie freno posteriori',
  22: 'Dischi freno anteriori',
  23: 'Dischi freno posteriori',
  24: 'Tamburi freno',
  25: 'Ceppi freno',
  26: 'Liquido freni',
  27: 'Pompa freno',
  28: 'Ammortizzatori anteriori',
  29: 'Ammortizzatori posteriori',
  30: 'Molle anteriori',
  31: 'Molle posteriori',
  32: 'Silent block',
  33: 'Bracci sospensione',
  34: 'Tiranti sterzo',
  35: 'Scatola sterzo',
  36: 'Cambio',
  37: 'Frizione',
  38: 'Disco frizione',
  39: 'Volano',
  40: 'Cinghia trasmissione',
  41: 'Variatore',
  42: 'Giunto cardanico',
  43: 'Semiassi',
  44: 'Cuscinetti ruota',
  45: 'Marmitta',
  46: 'Catalizzatore',
  47: 'Collettore scarico',
  48: 'Silenziatore',
  49: 'Tubo di scarico',
  50: 'Sonda lambda',
  51: 'Alternatore',
  52: 'Motorino avviamento',
  53: 'Batteria',
  54: 'Bobina accensione',
  55: 'Centralina',
  56: 'Regolatore di tensione',
  57: 'Relay',
  58: 'Fusibili',
  59: 'Faro anteriore sinistro',
  60: 'Faro anteriore destro',
  61: 'Luce posteriore sinistra',
  62: 'Luce posteriore destra',
  63: 'Luce posizione anteriore sinistra',
  64: 'Luce posizione anteriore destra',
  65: 'Luce posizione posteriore sinistra',
  66: 'Luce posizione posteriore destra',
  67: 'Lampada targa',
  68: 'Luce freno',
  69: 'Freccia anteriore sinistra',
  70: 'Freccia anteriore destra',
  71: 'Freccia posteriore sinistra',
  72: 'Freccia posteriore destra',
  73: 'Radiatore',
  74: 'Pompa acqua',
  75: 'Termostato',
  76: 'Vaschetta espansione',
  77: 'Ventola raffreddamento',
  78: 'Liquido raffreddamento',
  79: 'Manicotti raffreddamento',
  80: 'Serbatoio carburante',
  81: 'Pompa carburante',
  82: 'Iniettori',
  83: 'Carburatore',
  84: 'Corpo farfallato',
  85: 'Tubo carburante',
  86: 'Pneumatici',
  87: 'Cerchi',
  88: 'Valvole pneumatici',
  89: 'Cintura di sicurezza',
  90: 'Parabrezza',
  91: 'Tergicristalli',
  92: 'Pompa tergicristalli',
  93: 'Specchietto sinistro',
  94: 'Specchietto destro',
  95: 'altro',
};

/// Catalogo arricchito usato dalle nuove superfici WorkLog.
///
/// I nomi continuano a derivare dalla mappa compatibile sopra; la categoria è
/// dominio puro e potrà pilotare filtri e immagini senza entrare nella UI.
final Map<int, WorkLogPartCatalogEntry> kWorkLogPartsCatalog =
    Map.unmodifiable({
      for (final part in kPartsCatalog.entries)
        part.key: WorkLogPartCatalogEntry(
          name: part.value,
          category: _categoryForPartId(part.key),
        ),
    });

const _enginePartIds = <int>{
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  18,
  19,
  45,
  46,
  47,
  48,
  49,
  50,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
};

const _tirePartIds = <int>{86, 87, 88};
const _gearboxPartIds = <int>{36, 37, 38, 39, 40, 41, 42, 43};
const _brakePartIds = <int>{20, 21, 22, 23, 24, 25, 26, 27};
const _chassisPartIds = <int>{
  28,
  29,
  30,
  31,
  32,
  33,
  34,
  35,
  44,
  89,
  90,
  91,
  92,
  93,
  94,
};
const _electronicsPartIds = <int>{
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  58,
  59,
  60,
  61,
  62,
  63,
  64,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
};

WorkLogPartCategory _categoryForPartId(int partId) {
  if (_tirePartIds.contains(partId)) return WorkLogPartCategory.tires;
  if (_gearboxPartIds.contains(partId)) return WorkLogPartCategory.gearbox;
  if (_brakePartIds.contains(partId)) return WorkLogPartCategory.brakes;
  if (_chassisPartIds.contains(partId)) return WorkLogPartCategory.chassis;
  if (_electronicsPartIds.contains(partId)) {
    return WorkLogPartCategory.electronics;
  }
  if (_enginePartIds.contains(partId)) return WorkLogPartCategory.engine;
  return WorkLogPartCategory.vehicle;
}
