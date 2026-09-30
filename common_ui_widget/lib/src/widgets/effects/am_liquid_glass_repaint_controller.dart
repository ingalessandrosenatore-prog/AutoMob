import 'package:flutter/foundation.dart';

/// Inoltra al gruppo Liquid Glass i frame delle animazioni dei suoi controlli.
///
/// Un solo controller puo' essere condiviso da piu' superfici appartenenti
/// allo stesso gruppo: il valore espone l'ultima scala ricevuta, mentre ogni
/// aggiornamento notifica il repaint dello shader unificato.
class AmLiquidGlassRepaintController extends ChangeNotifier {
  double _scale = 1;
  Listenable? _externalRepaint;

  double get scale => _scale;

  void updateScale(double scale) {
    _scale = scale;
    notifyListeners();
  }

  void bindExternalRepaint(Listenable? repaint) {
    if (identical(repaint, _externalRepaint)) return;
    _externalRepaint?.removeListener(_forwardExternalRepaint);
    _externalRepaint = repaint;
    _externalRepaint?.addListener(_forwardExternalRepaint);
  }

  void _forwardExternalRepaint() => notifyListeners();

  @override
  void dispose() {
    _externalRepaint?.removeListener(_forwardExternalRepaint);
    super.dispose();
  }
}
