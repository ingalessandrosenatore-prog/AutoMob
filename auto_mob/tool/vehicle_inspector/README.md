# AutoMob Vehicle Inspector

Carrozzeria fastback X-Ray ispirata alle proporzioni dell’Alfa Romeo Giulia,
con cofano lungo, abitacolo arretrato, spalle larghe e frontale a trilobo.
Il modello conserva il quattro cilindri trasversale e la trazione anteriore.
La scena usa geometrie indipendenti, materiali PBR senza texture e luci neutre.
Il GLB lascia al renderer la gestione dell’illuminazione e dello sfondo.

- `automob_vehicle.blend` contiene la scena modificabile in Blender 5.2.
- `automob_vehicle.glb` è l’asset glTF 2.0 per il renderer.
- `components.json` contiene la mappa dei componenti e le inquadrature.
- `index.html` apre il demo Three.js con selezione e orbita.

## Aprire il demo

Dalla radice del repository:

```powershell
python -m http.server 8769 --bind 127.0.0.1 --directory ./auto_mob/tool/vehicle_inspector
```

Apri [il demo in locale](http://127.0.0.1:8769/). Il browser richiede WebGL e
una connessione per scaricare Three.js 0.180.0 da jsDelivr.

Tocca una ruota dalla vista generale per avvicinarti e vedere freni e
sospensioni. Tocca un pezzo o sceglilo dal menu per evidenziarlo e leggere
l’ID. Usa un dito per ruotare, due dita per zoomare o spostare la vista.
Con il mouse usa trascinamento, rotellina e tasto destro.

## Collegare un renderer

Il GLB usa metri, con `+X` verso il muso, `+Y` verso l’alto e `−Z` verso il
lato sinistro. Le coordinate del JSON e degli `extras` sono già in spazio
glTF. La scena Blender usa `+X` verso il muso, `+Y` verso sinistra e `+Z`
verso l’alto. Il passo è di 2,60 m.

1. Cerca i nodi per nome sotto `AutoMob_Vehicle`. Carica `components.json`
   oppure leggi le proprietà dei componenti dagli `extras` del GLB.
2. Evidenzia le mesh elencate in `meshNames`, usando il materiale
   `MAT_SELECTED` o un override locale con il colore `#FF6A00`. Le varianti
   `MAT_INTERACTIVE` e `MAT_SELECTED` sono esportate tramite
   `KHR_materials_variants`. Applica gli override alla singola istanza per
   preservare le mesh condivise dalle quattro ruote.
3. Usa la posizione del nodo `anchor_*` e `pickRadiusMeters` in un test
   raggio-sfera per recuperare i tocchi vicino ai pezzi piccoli. Il demo
   conserva il raycast sulla geometria e dà priorità alle parti interne quando
   il pneumatico è attenuato.
4. Anima la camera verso `cameraPresets`. Ogni preset include posizione,
   target, distanza e campo visivo verticale in gradi. Il `target` del
   componente centra il dettaglio selezionato.

Il demo emette `automob:selection` su `#stage`, con l’ID del componente in
`event.detail` e `null` quando la selezione viene azzerata. Il modello e il
demo sono pronti per il collaudo nel renderer scelto per Flutter.

## Rigenerare e verificare

Dalla radice del repository:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python ./auto_mob/tool/vehicle_inspector/build_vehicle.py
python ./auto_mob/tool/vehicle_inspector/check_export.py
```

Lo script genera Blend, GLB e JSON nella propria cartella. Accetta
`-- --output <cartella>` per una destinazione diversa e
`-- --preview <percorso.png>` per un render con sfondo trasparente. Gli script
separano carrozzeria, organi meccanici, materiali, geometrie e metadati.

| Misura del GLB | Valore |
|---|---:|
| Nodi (mesh, gruppi e anchor) | 428 |
| Oggetti mesh | 326 |
| Mesh distinte | 197 |
| Vertici memorizzati | 21.929 |
| Vertici conteggiando le istanze | 45.011 |
| Triangoli conteggiando le istanze | 60.692 |
| Componenti selezionabili | 55 |
| Preset camera | 14 |
| Dimensione | 840.768 byte |

Il conteggio per istanza include tutte le copie visibili delle mesh condivise.
