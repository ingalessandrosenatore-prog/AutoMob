import 'package:flutter/widgets.dart';

/// Builder di pagine cross-feature, risolti via get_it.
///
/// Servono quando una feature deve COSTRUIRE (non solo navigare verso) la
/// pagina di un'altra feature — es. la home che apre la registrazione
/// veicolo dentro una transizione LiquidZoom, dove la destinazione deve
/// vivere nell'overlay del morph e non in una route go_router. La regola
/// cross-feature vieta a dashboard di importare la presentation di vehicle:
/// il typedef sta in core e l'implementazione la monta il composition root
/// (`core/di/injection_container.dart`), che le feature le conosce tutte.
///
/// `close` è la chiusura ANIMATA fornita dalla transizione: la pagina deve
/// usare quella, non `Navigator.pop` diretto.
typedef VehicleRegistrationZoomBuilder = Widget Function(
  BuildContext context,
  VoidCallback close,
);
