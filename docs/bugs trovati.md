# Bug tracciati e priorità

## 1. KPI / valori predefiniti in registrazione

- Priorità: 1 (massima).
- Problema: le KPI non gestiscono correttamente l'assenza dei valori predefiniti; in particolare la distribuzione non viene visualizzata nemmeno dopo l'inserimento di lavori successivi.
- Richiesta: creare e aggiornare correttamente le KPI sia senza valori iniziali sia quando il valore viene inserito in seguito.

## 3. Registrazione veicolo / step targa / colore testo

- Priorità: 3.
- Problema: con il codice meccanico, nello step targa il testo non usa il colore primario e risulta bianco su bianco; anche l'icona resta arancione e nera nel tema chiaro.
- Richiesta: rendere palette, testo e icone coerenti nei temi chiaro e scuro.

## 4. Backoffice meccanico

- Stato: risolto.
- Problema: label, icone e colori testo non sono coerenti fra gli step.
- Correzione: tipografia e colori della home meccanico sono ora allineati ai token del tema.

## 5. Card veicoli troppo grandi

- Priorità: 2.
- Stato: risolto.
- Problema: le card dei veicoli sono troppo alte.
- Correzione: spaziature, badge e metadati sono stati compattati senza ridurre il target tattile.

## 6. Soft edge blur superiore / app bar

- Priorità: 2.
- Stato: risolto.
- Problema: il blur sotto l'app bar deve estendersi di circa 20–30 px in più.
- Correzione: estensione superiore portata da 72 a 100 px.

## 7. Icone meccanico / pulsanti

- Priorità: 1.
- Stato: risolto.
- Problema: l'app meccanica usa pulsanti icona locali invece del componente AutoMob.
- Correzione: `AmSoftButton` è ora esportato da `common_ui_widget` e sostituisce il componente locale.

## 8. Navigation bar / OCLiquidGlass

- Priorità: 1.
- Stato: risolto.
- Problema: il liquid glass della navigation bar deve essere attivabile e disattivabile.
- Correzione: `AppShell.liquidGlassEnabled` seleziona vetro o superficie opaca.

## 9. Filtri / input testo / input voce / tastiera

- Priorità: 1.
- Stato: risolto.
- Problema: contenuto e wrapper glass devono muoversi insieme con la tastiera e restare appena sopra di essa.
- Correzione: la riga è un unico `AnimatedPositioned` e ora resta a 4 px dalla tastiera.

Usare nell'app meccanica queste impostazioni condivise per il liquid glass:

```dart
OCLiquidGlassSettings(
  refractStrength: -0.08,
  blurRadiusPx: 1.0,
  specStrength: 0,
  specWidth: 0.0,
  specAngle: 145,
  blendPx: 70,
  specPower: 10,
)
```

## Conclusione

- KPI: priorità 1, perché impatta calcolo e visibilità dei dati.
- Problemi grafici dell'app meccanica: priorità 1–3 secondo l'elemento coinvolto.
