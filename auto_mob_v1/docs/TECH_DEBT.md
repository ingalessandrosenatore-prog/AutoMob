# Debito tecnico — architettura

Queste violazioni esistevano **prima** di introdurre `tool/check_architecture.dart`.
Sono tracciate in `tool/arch_baseline.txt` (quindi **non** bloccano i commit), ma
vanno ripagate. Quando ne sistemi una, **cancella la riga corrispondente** dal
baseline: da quel momento il check la considererà di nuovo un errore da evitare.

Il gate resta severo sulle violazioni **nuove**: il debito non può crescere.

Le baseline architetturali ora usano firme stabili, indipendenti dal numero di
linea:

```text
REGOLA|file|messaggio normalizzato
```

Il gate blocca inoltre:

- `R14`: pagine/widget che importano use case o repository;
- `R15`: `GetIt` fuori da `main.dart`, `core/di` e `core/router`;
- `R16`: BLoC/Cubit che dipendono direttamente da repository;
- `R17`: Firebase, Supabase e SharedPreferences nella presentation;
- `R18`: nuovi `setState` senza eccezione locale motivata;
- `R19`: uso del service locator fuori dal composition root.

Il debito R18/R19 preesistente e' nel baseline. Non e' consentito aggiungervi
codice introdotto da una nuova feature.

---

## 1. `AmSparePartCard` è in `core/` ma dipende da `work_log`

**File:** `lib/core/widgets/card/am_spare_part_card.dart`
**Regole:** `R8` (riga 1) + `R13` (righe 194, 215, 258)

Il widget sta in `core/widgets/` — cioè dichiarato "riutilizzabile e trasversale" —
ma importa `features/work_log/domain/entities/selected_part.dart`. Quindi in realtà
**non è core**: è un widget specifico di `work_log`.

**Come ripagare:**
1. Spostare il file in `lib/features/work_log/presentation/widgets/`.
2. Estrarre i tre metodi che ritornano `Widget` (`_buildDeleteBackground`,
   `_buildQuantitySelector`, `_buildCircleBtn`) in altrettante **widget class private**.
3. Rimuovere le 4 righe relative dal baseline.

---

## 2. `home_view` (dashboard) usa direttamente l'`AuthBloc` per il logout

**File:** `lib/features/dashboard/presentation/pages/home_view.dart`
**Regola:** `R9` (righe 12, 13)

La `dashboard` importa la **presentation** della feature `auth` (`auth_bloc`,
`auth_event`) per far partire il logout. La regola morbida ammette il cross-feature
solo verso il `domain` di un'altra feature, non verso la sua presentation.

Qui `auth` funziona di fatto come **sessione globale**. Due strade pulite:
- esporre un'azione di logout tramite un'**interfaccia nel `core`** (es. un
  `SessionService`) che la dashboard usa senza conoscere l'`AuthBloc`, **oppure**
- gestire il logout dalla UI della feature `auth` (la dashboard naviga/segnala,
  auth esegue).

**Come ripagare:** applicare una delle due strade e rimuovere le 2 righe dal baseline.

---

# Debito tecnico — flutter analyze

Questi sono soppressi puntualmente con `// ignore: <regola>` nel punto esatto
(non con un'esclusione generale), quindi restano visibili in-place e
`flutter analyze` torna verde. Quando ne ripaghi uno, **rimuovi il commento
`// ignore:`** insieme al codice morto/warning che copriva.

## 3. `am_glass_fab.dart` — animazione di rotazione mai completata

**Righe:** 48 (`_rotationAnimation`), 176 (`iconScale`, `currentRotation`), 225 (`.scale()` deprecato)

Sembra un'animazione di rotazione/scala abbozzata e mai finita: il campo e le
variabili locali vengono assegnati ma mai letti da nessun builder. Il metodo
`.scale()` di `Matrix4` è inoltre deprecato (l'alternativa richiede costruire
un `Vector3` esplicito, quindi tocca la logica, non solo il nome).

**Come ripagare:** decidere se completare l'animazione di rotazione (leggerla
davvero in un `Transform.rotate`) o eliminarla del tutto (campo + variabili +
l'assegnazione nei rami if/else). Migrare `.scale()` a `scaleByVector3(...)`
verificando visivamente che il comportamento non cambi.

## 4. `shell_scaffold.dart:106` — `_onCancel()` mai chiamato

Metodo gemello di `_onRelese()` (stessa spring animation) ma non collegato a
nessun gesture handler (manca l'`onTapCancel` che lo invocherebbe).

**Come ripagare:** o collegarlo a `onTapCancel` nel `GestureDetector`, o
eliminarlo se il comportamento "annulla il tap" non serve.

## 5. `card_auto.dart` — `_kTileLabel` morta, `watermarkColor` mai passato

`_kTileLabel` (riga 153) è uno stile mai usato. `watermarkColor` (riga 267) è
un parametro del costruttore di `_TapTile` usato *internamente* al widget
(riga con `?? _kAppOrange`) ma nessun chiamante lo valorizza mai.

**Come ripagare:** eliminare `_kTileLabel` se non serve più altrove; per
`watermarkColor` decidere se va esposto a qualche chiamante reale o
semplificato togliendo il parametro e tenendo sempre `_kAppOrange`.

## 6. `vehicle_remote_data_source.dart:29` — `owner_id` non lowerCamelCase

Getter chiamato `owner_id` invece di `ownerId` (convenzione Dart). Usato in
5 punti nello stesso file.

**Come ripagare:** rinominare `owner_id` → `ownerId` e aggiornare tutti gli
usi nel file in un colpo solo (find & replace mirato).
