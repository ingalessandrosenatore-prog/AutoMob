import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../vehicle/domain/entities/mechanic_summary.dart';
import '../../domain/entities/workshop_mascot.dart';
import 'workshop_depth_fallback.dart';

/// Carousel delle officine/meccanici.
///
/// Il widget può funzionare in due modalità:
///
/// 1. **WebGL / WebView**
///    Se viene fornito [sceneUrl] e la piattaforma è Android/iOS,
///    viene caricata una scena WebGL all'interno di una [WebViewWidget].
///
/// 2. **Fallback Flutter**
///    Se la WebView non è disponibile oppure [sceneUrl] è `null`,
///    viene mostrato [WorkshopDepthFallback].
///
/// La scena WebGL non viene ricreata per ogni officina:
/// esiste una sola scena e viene comunicato a JavaScript quale
/// officina/personaggio è attualmente selezionato.
///
/// Flutter comunica con JavaScript attraverso il canale:
///
/// ```text
/// WorkshopBridge
/// ```
///
/// mentre Flutter invia comandi alla pagina tramite funzioni globali JS come:
///
/// ```text
/// window.setWorkshops(...)
/// window.setSceneVisible(...)
/// ```
class AmWorkshopCarousel extends StatefulWidget {
  /// Crea il carousel delle officine.
  ///
  /// [mechanics] contiene le officine/meccanici da visualizzare.
  ///
  /// [variants] contiene la configurazione grafica delle mascotte
  /// associate ai meccanici.
  ///
  /// [selectedIndex] rappresenta l'elemento attualmente selezionato.
  ///
  /// L'indice `0` sembra essere riservato all'elemento "Aggiungi officina",
  /// mentre gli indici successivi rappresentano i meccanici.
  const AmWorkshopCarousel({
    super.key,
    required this.mechanics,
    required this.onAdd,
    required this.onMechanicTap,
    this.variants = const [],
    this.selectedIndex = 0,
    this.onSelected,
    this.sceneUrl,
  });

  /// Elenco dei meccanici/officine disponibili.
  final List<MechanicSummary> mechanics;

  /// Configurazioni grafiche delle mascotte.
  ///
  /// Ogni [WorkshopMascot] viene associato ad un meccanico tramite
  /// `mechanicId`.
  final List<WorkshopMascot> variants;

  /// Indice dell'elemento attualmente selezionato.
  ///
  /// Convenzione utilizzata dalla classe:
  ///
  /// - `0` → aggiunta officina
  /// - `1` → `mechanics[0]`
  /// - `2` → `mechanics[1]`
  /// - ecc.
  final int selectedIndex;

  /// Callback chiamata quando cambia l'elemento selezionato.
  ///
  /// Riceve l'indice selezionato.
  final ValueChanged<int>? onSelected;

  /// Callback chiamata quando viene richiesta l'aggiunta
  /// di una nuova officina.
  final VoidCallback onAdd;

  /// Callback chiamata quando l'utente apre un meccanico.
  ///
  /// Restituisce direttamente il [MechanicSummary] selezionato.
  final ValueChanged<MechanicSummary> onMechanicTap;

  /// URL della pagina contenente la scena WebGL.
  ///
  /// Se `null`, il widget utilizza [WorkshopDepthFallback].
  final String? sceneUrl;

  @override
  State<AmWorkshopCarousel> createState() => _AmWorkshopCarouselState();
}

/// Stato interno di [AmWorkshopCarousel].
///
/// Implementa [WidgetsBindingObserver] perché deve conoscere
/// lo stato dell'applicazione.
///
/// Ad esempio, quando l'app va in background, comunica alla scena WebGL
/// di smettere di renderizzare per evitare consumo inutile di risorse.
class _AmWorkshopCarouselState extends State<AmWorkshopCarousel>
    with WidgetsBindingObserver {
  /// Mantiene internamente l'indice selezionato.
  ///
  /// Viene utilizzato un [ValueNotifier] invece di chiamare [setState]
  /// per ogni cambio di selezione.
  ///
  /// In questo modo solo il [ValueListenableBuilder] interessato
  /// viene ricostruito.
  late final ValueNotifier<int> _selected;

  /// Controller della WebView che contiene la scena WebGL.
  ///
  /// Se vale `null`, significa che la scena WebGL non è disponibile
  /// e verrà utilizzato il fallback Flutter.
  WebViewController? _web;

  /// Inizializza lo stato del widget.
  ///
  /// Qui vengono eseguite tre operazioni principali:
  ///
  /// 1. Registrazione come observer del lifecycle dell'app.
  /// 2. Creazione del [ValueNotifier] con l'indice iniziale.
  /// 3. Eventuale inizializzazione della WebView.
  @override
  void initState() {
    super.initState();

    /// Permette a questa classe di ricevere eventi come:
    ///
    /// - app in background
    /// - app riaperta
    /// - app inattiva
    WidgetsBinding.instance.addObserver(this);

    /// Copia lo stato iniziale ricevuto dal parent.
    _selected = ValueNotifier(widget.selectedIndex);

    /// La WebView viene utilizzata solamente:
    ///
    /// - fuori da Flutter Web
    /// - su Android oppure iOS
    /// - quando è disponibile un URL della scena
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        widget.sceneUrl != null) {
      try {
        _web = WebViewController()
          /// Permette alla pagina WebGL di eseguire JavaScript.
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          /// Mantiene trasparente lo sfondo della WebView,
          /// utile se la scena deve fondersi con la UI Flutter.
          ..setBackgroundColor(Colors.transparent)
          /// Crea un ponte JavaScript → Flutter.
          ///
          /// La pagina web può quindi fare qualcosa del tipo:
          ///
          /// ```javascript
          /// WorkshopBridge.postMessage(
          ///   JSON.stringify({...})
          /// );
          /// ```
          ///
          /// Il messaggio verrà ricevuto da [_onWebMessage].
          ..addJavaScriptChannel(
            'WorkshopBridge',
            onMessageReceived: _onWebMessage,
          )
          /// Permette di osservare gli eventi di navigazione della WebView.
          ..setNavigationDelegate(
            NavigationDelegate(
              /// Quando la pagina è completamente caricata,
              /// inviamo alla scena la configurazione delle officine.
              onPageFinished: (_) => _sendConfiguration(),
            ),
          )
          /// Carica la pagina WebGL.
          ..loadRequest(Uri.parse(widget.sceneUrl!));
      } catch (_) {
        /// Se la WebView non può essere creata,
        /// viene automaticamente utilizzato il fallback Flutter.
        _web = null;
      }
    }
  }

  /// Chiamato quando il widget padre ricostruisce [AmWorkshopCarousel]
  /// passando nuovi parametri.
  ///
  /// Viene utilizzato per sincronizzare lo stato interno con:
  ///
  /// - [AmWorkshopCarousel.selectedIndex]
  /// - [AmWorkshopCarousel.mechanics]
  /// - [AmWorkshopCarousel.variants]
  @override
  void didUpdateWidget(covariant AmWorkshopCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Se il parent modifica la selezione,
    /// aggiorniamo anche il nostro stato locale.
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selected.value = widget.selectedIndex;
    }

    /// Se cambiano i dati rilevanti per la scena,
    /// inviamo nuovamente la configurazione alla WebView.
    if (oldWidget.mechanics != widget.mechanics ||
        oldWidget.variants != widget.variants ||
        oldWidget.selectedIndex != widget.selectedIndex) {
      _sendConfiguration();
    }
  }

  /// Libera le risorse utilizzate dal widget.
  @override
  void dispose() {
    /// Non vogliamo più ricevere notifiche sul lifecycle dell'app.
    WidgetsBinding.instance.removeObserver(this);

    /// Comunica alla scena WebGL che non deve più renderizzare.
    ///
    /// `?.` in JavaScript significa:
    /// "chiama la funzione solamente se esiste".
    _sendScript('window.setSceneVisible?.(false)');

    /// Elimina il ValueNotifier.
    _selected.dispose();

    super.dispose();
  }

  /// Riceve le variazioni dello stato dell'applicazione.
  ///
  /// L'obiettivo principale è sospendere il rendering WebGL
  /// quando l'app non è visibile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sendScript(
      'window.setSceneVisible?.(${state == AppLifecycleState.resumed})',
    );
  }

  /// Esegue uno script JavaScript all'interno della WebView.
  ///
  /// [script] contiene il codice JavaScript da eseguire.
  ///
  /// Il metodo è protetto da `try/catch` perché durante una navigazione
  /// la WebView potrebbe essere già in fase di distruzione mentre
  /// un comando JavaScript è ancora in coda.
  Future<void> _sendScript(String script) async {
    try {
      await _web?.runJavaScript(script);
    } catch (_) {
      /// Ignora gli errori provocati da una WebView
      /// che sta venendo rimossa/distrutta.
    }
  }

  /// Gestisce i messaggi inviati dalla pagina JavaScript a Flutter.
  ///
  /// Il messaggio deve essere una stringa JSON.
  ///
  /// Esempi:
  ///
  /// ```json
  /// {"type": "ready"}
  /// ```
  ///
  /// ```json
  /// {"type": "selected", "index": 2}
  /// ```
  ///
  /// ```json
  /// {"type": "add"}
  /// ```
  ///
  /// ```json
  /// {"type": "open", "index": 1}
  /// ```
  void _onWebMessage(JavaScriptMessage message) {
    /// Se il widget è già stato rimosso dall'albero Flutter,
    /// non facciamo nulla.
    if (!mounted) return;

    try {
      /// Converte la stringa JSON ricevuta in una Map Dart.
      final data = jsonDecode(message.message) as Map<String, dynamic>;

      /// Decide l'azione da eseguire in base al campo "type".
      switch (data['type']) {
        /// La scena JavaScript comunica di essere pronta.
        ///
        /// Flutter risponde inviandole tutti i dati.
        case 'ready':
          _sendConfiguration();

        /// L'utente ha cambiato personaggio/officina
        /// direttamente dentro la scena WebGL.
        case 'selected':
          _select((data['index'] as num).toInt());

        /// L'utente ha premuto l'elemento "Aggiungi officina".
        case 'add':
          widget.onAdd();

        /// L'utente vuole aprire il dettaglio di un'officina.
        case 'open':
          final index = (data['index'] as num).toInt();

          /// L'indice 0 non rappresenta un meccanico.
          ///
          /// Per questo motivo:
          ///
          /// index 1 -> mechanics[0]
          /// index 2 -> mechanics[1]
          /// ecc.
          if (index > 0 && index <= widget.mechanics.length) {
            widget.onMechanicTap(widget.mechanics[index - 1]);
          }
      }
    } catch (_) {
      /// Ignora messaggi JSON non validi oppure messaggi
      /// provenienti da una vecchia pagina durante una navigazione.
    }
  }

  /// Invia alla scena WebGL la configurazione completa delle officine.
  ///
  /// Il metodo costruisce un JSON contenente:
  ///
  /// - indice selezionato
  /// - id meccanico
  /// - nome officina
  /// - posa della mascotte
  /// - oggetto/strumento della mascotte
  /// - colore principale
  /// - colore secondario
  ///
  /// Infine esegue:
  ///
  /// ```javascript
  /// window.setWorkshops(payload)
  /// ```
  void _sendConfiguration() {
    /// Manteniamo una copia locale per evitare
    /// accessi ripetuti al campo `_web`.
    final web = _web;

    /// Senza WebView non abbiamo nulla a cui inviare i dati.
    if (web == null) return;

    /// Trasforma la lista delle varianti in una Map:
    ///
    /// mechanicId -> WorkshopMascot
    ///
    /// Esempio:
    ///
    /// {
    ///   "123": mascotMario,
    ///   "456": mascotLuigi,
    /// }
    ///
    /// Questo permette di recuperare una variante per ID
    /// molto più comodamente rispetto alla ricerca nella lista.
    final byId = {for (final item in widget.variants) item.mechanicId: item};

    /// Crea il JSON che verrà inviato a JavaScript.
    final payload = jsonEncode({
      'selected': _selected.value,

      'items': [
        for (final mechanic in widget.mechanics)
          /// Pattern matching Dart.
          ///
          /// Se esiste una variante associata al mechanic.id,
          /// la salva nella variabile `variant`.
          ///
          /// Se non esiste, quel meccanico non viene aggiunto
          /// all'array inviato alla WebView.
          if (byId[mechanic.id] case final variant?)
            {
              'id': mechanic.id,
              'name': mechanic.businessName,
              'pose': variant.pose,
              'prop': variant.prop,
              'baseColor': variant.baseColor,
              'accentColor': variant.accentColor,
            },
      ],
    });

    /// Chiama la funzione JavaScript globale `setWorkshops`
    /// passando direttamente il JSON.
    ///
    /// Dopo jsonEncode, per esempio potrebbe diventare:
    ///
    /// window.setWorkshops?.({
    ///   "selected": 1,
    ///   "items": [...]
    /// });
    _sendScript('window.setWorkshops?.($payload)');
  }

  /// Cambia l'elemento attualmente selezionato.
  ///
  /// [index] deve essere compreso tra:
  ///
  /// ```text
  /// 0 ... mechanics.length
  /// ```
  ///
  /// dove `0` rappresenta l'elemento speciale
  /// per aggiungere una nuova officina.
  void _select(int index) {
    /// Protezione contro indici non validi.
    if (index < 0 || index > widget.mechanics.length) return;

    /// Se è già selezionato, non facciamo nulla.
    if (_selected.value == index) return;

    /// Aggiorna il ValueNotifier.
    ///
    /// Questo provoca automaticamente il rebuild
    /// del ValueListenableBuilder presente nel build().
    _selected.value = index;

    /// Comunica al widget padre il nuovo indice.
    widget.onSelected?.call(index);
  }

  /// Costruisce l'interfaccia del carousel.
  ///
  /// La struttura finale è:
  ///
  /// ```text
  /// SizedBox
  /// └── ValueListenableBuilder
  ///     └── Column
  ///         ├── Expanded
  ///         │   ├── WebViewWidget
  ///         │   └── oppure WorkshopDepthFallback
  ///         │
  ///         ├── SizedBox
  ///         │
  ///         └── Row
  ///             └── indicatori del carousel
  /// ```
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      /// Altezza fissa dell'intero carousel.
      height: 280,

      /// Occupa tutta la larghezza disponibile.
      width: double.infinity,

      /// Ascolta [_selected].
      ///
      /// Ogni volta che `_selected.value` cambia,
      /// viene rieseguito solamente questo builder.
      child: ValueListenableBuilder<int>(
        valueListenable: _selected,

        /// `index` contiene il valore corrente di `_selected`.
        builder: (context, index, _) => Column(
          children: [
            Expanded(
              /// Se la WebView non esiste viene mostrata
              /// l'implementazione Flutter alternativa.
              child: _web == null
                  ? WorkshopDepthFallback(
                      mechanics: widget.mechanics,

                      /// Elemento attualmente selezionato.
                      selected: index,

                      /// Cambio selezione nel fallback.
                      onSelect: _select,

                      /// Aggiunta nuova officina.
                      onAdd: widget.onAdd,

                      /// Apertura dettaglio meccanico.
                      onOpen: widget.onMechanicTap,
                    )
                  /// Altrimenti mostriamo la scena WebGL.
                  : WebViewWidget(
                      controller: _web!,

                      /// Dice a Flutter che la WebView deve poter
                      /// ricevere gesture di trascinamento orizzontale.
                      ///
                      /// Utile per implementare lo swipe/carousel
                      /// direttamente nella scena WebGL.
                      gestureRecognizers: const {
                        Factory<HorizontalDragGestureRecognizer>(
                          HorizontalDragGestureRecognizer.new,
                        ),
                      },
                    ),
            ),

            const SizedBox(height: 3),

            /// Indicatori inferiori del carousel.
            ///
            /// Viene creato un indicatore anche per l'indice 0,
            /// quindi il numero totale è:
            ///
            /// mechanics.length + 1
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i <= widget.mechanics.length; i++)
                  /// AnimatedContainer permette di animare
                  /// automaticamente larghezza e colore
                  /// quando cambia la selezione.
                  AnimatedContainer(
                    key: Key('workshop_indicator_$i'),

                    /// Durata dell'animazione dell'indicatore.
                    duration: const Duration(milliseconds: 230),

                    /// L'indicatore selezionato diventa una pillola.
                    ///
                    /// selezionato: 25px
                    /// normale:     7px
                    width: i == index ? 25 : 7,

                    height: 7,

                    margin: const EdgeInsets.symmetric(horizontal: 3),

                    decoration: BoxDecoration(
                      /// Arancione per l'elemento selezionato,
                      /// grigio per gli altri.
                      color: i == index
                          ? const Color(0xFFFF7926)
                          : const Color(0xFF66666B),

                      /// Rende gli indicatori arrotondati.
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
