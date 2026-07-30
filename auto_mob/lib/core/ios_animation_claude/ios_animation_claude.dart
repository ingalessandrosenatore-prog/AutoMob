/// Liquid zoom transition — la "zoom transition" di iOS ricreata in Flutter.
///
/// Punto d'ingresso unico del pacchetto: importare questo file, avvolgere il
/// widget sorgente in [LiquidZoom] e indicare destinazione ([LiquidZoomTarget])
/// e contenuto (`destinationBuilder`). Fisica ed estetica si regolano con
/// [LiquidZoomConfig] (molle, luce, blur, scrim, raggi, ombra).
library;

export 'liquid_glow_painter.dart';
export 'liquid_zoom.dart';
export 'liquid_zoom_config.dart';
export 'liquid_zoom_overlay.dart';
export 'liquid_zoom_target.dart';
