# iOS Liquid Zoom

Transizione modulare ispirata alla `NavigationTransition.zoom` di SwiftUI. Non
dipende dai widget liquid-glass del progetto: anima geometria, luce, blur,
contenuto e ritorno al trigger, mentre la destinazione resta un normale widget
Flutter dentro una route del `Navigator`.

Import unico:

```dart
import 'package:auto_mob_v1/core/ios_animation_gbt/ios_animation_gbt.dart';
```

## Bottone verso una pagina

Per un bottone già interattivo usa il builder e collega `zoom.open()` al suo
callback. Dentro la pagina `zoom.close(result)` oppure `Navigator.pop(context)`
eseguono automaticamente la transizione inversa.

```dart
IosLiquidZoom<bool>(
  layout: const IosLiquidPageLayout(),
  config: const IosLiquidZoomConfig(
    destinationBorderRadius: BorderRadius.zero,
  ),
  sourceBuilder: (context, zoom) => FilledButton(
    onPressed: () => zoom.open(),
    child: const Text('Apri pagina'),
  ),
  destinationBuilder: (context, zoom) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => zoom.close(true)),
    ),
    body: const Center(child: Text('Pagina')), 
  ),
)
```

## Card verso un modale

`IosLiquidZoomTap` è la scorciatoia per widget non ancora interattivi.

```dart
IosLiquidZoomTap<void>(
  source: const MyVehicleCard(),
  destination: const VehicleDetailsModal(),
  layout: const IosLiquidModalLayout(
    alignment: Alignment.bottomCenter,
    height: 520,
    margin: EdgeInsets.all(16),
  ),
  config: const IosLiquidZoomConfig(
    surfaceColor: Color(0xFF232326),
    barrierColor: Color(0x66000000),
  ),
)
```

## Popup ancorato

```dart
IosLiquidZoomTap<void>(
  source: const Icon(Icons.more_horiz),
  destination: const ActionsPopup(),
  layout: const IosLiquidPopupLayout(size: Size(260, 220)),
)
```

`IosLiquidZoomController<T>` è opzionale e permette apertura/chiusura da codice
e osservazione delle fasi `idle`, `lifting`, `opening`, `open`, `closing` e
`settling`. `IosLiquidZoomConfig` espone durate, spring, lift, scale, blur,
colori, raggi, barriera e snapshot del trigger. Per geometrie speciali è
disponibile `IosLiquidCustomLayout`.
