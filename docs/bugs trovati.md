Bug tracciati e priorità

1) KPI / registration default values
- Priorità: 1 (massima)
- Problema: le KPI hanno bug durante la fase di registrazione quando non vengono inseriti i default values; in particolare la distribuzione è una KPI che non viene visualizzata se non inserita, e non compare nemmeno se aggiungo lavori in un momento successivo.
- Problema correlato: anche se registro successivamente un valore, l’app non crea la KPI, soprattutto quella di distribuzione.
- Segnalazione: il problema sembra riguardare una query o un flusso di aggiornamento delle KPI che non gestisce correttamente i valori di default e i successivi aggiornamenti.
- Richiesta: le KPI devono essere corrette e aggiornate correttamente anche quando i valori default non vengono registrati inizialmente e quando il valore viene inserito in un secondo momento.

2) Work log history / dropdown veicoli
- Priorità: 2
- Problema: nella dropdown della pagina di Work Log History, se cancello i veicoli, il dropdown non si aggiorna nemmeno dopo refresh della pagina.
- Possibile causa: il refresh della pagina non sta ricaricando correttamente lo stato dei dati o non aggiorna il dropdown dopo la cancellazione.
- Richiesta: verificare il refresh e l’aggiornamento del contenuto dinamico della dropdown.

3) Registrazione veicolo / step targa / colore testo
- Priorità: 3
- Problema: in fase di registrazione veicolo, quando si inserisce il codice meccanico, nello step della targa non viene usato il colore text primary e la scritta appare bianca su sfondo bianco.
- Problema grafico: l’icona continua ad essere arancione e nera, anche con tema chiaro.
- Richiesta: correggere palette colori e contrasto testo/icone in modo coerente con il tema chiaro e scuro.

4) Backoffice_mech
- Note: ci sono bug grafici attualmente nella app backoffice_mech.
- Necessità: verificare la coerenza visiva delle label, delle icone e del colore del testo nei vari step.

5) Card veicoli troppo grandi
- Priorità: 2
- Problema: le card dei veicoli risultano troppo alte e devono essere ridotte in altezza.
- Richiesta: ottimizzare il layout delle card per ottenere una densità visiva migliore senza perdere leggibilità.

6) Soft edge blur top / app bar
- Priorità: 2
- Problema: il soft edge blur sotto l’app bar deve essere più alto di circa 20/30 px.
- Richiesta: aumentare l’estensione dell’effetto blur nella zona superiore, in modo coerente con la UI e con il tema attivo.

7) Icone meccanico / plusanti
- Priorità: 1
- Problema: nell’app meccanica sono stati creati dei "plusanti" icon non corretti; non va bene usare pulsnati custom ad hoc invece di riutilizzare quelle già presenti nell’app AutoMob.
- Richiesta: esportare e centralizzare il pulsnate amSoftButton icon shared nel package comune, quindi riutilizzare gli stessi componenti/asset in tutta l’applicazione.
- Note: i componenti devono rispettare la stessa struttura e il medesimo comportamento del caso d’uso di AutoMob, evitando duplicazioni grafiche o incoerenze visuali.

8) Navigation bar / OCLiquidGlass
- Priorità: 1
- Problema: la navigation bar deve avere un OCLiquidGlass con un boolean che lo attiva/disattiva; il comportamento attuale va verificato e allineato al design richiesto.
- Richiesta: introdurre la gestione del liquid glass in modo coerente, con attivazione/disattivazione controllata tramite flag, e mantenere l’effetto visivo corretto in tutte le condizioni.
- Note: il codice riferimento richiesto è il seguente: per il pulsante del microfono usare AmSoftButton(width: 45, height: 45, color: colors.accent, icon: HugeIcons.strokeRoundedMic01, onPressed: () {}); per il pulsante dell’app bar impostazioni usare AmSoftButton(width: 45, height: 45, backgroundColor: kHeavyEffects ? colors.surfaceRaised.withValues(alpha: 0.2) : colors.surfaceRaised, popupBackgroundColor: kHeavyEffects ? colors.surfaceRaised.withValues(alpha: 0.5) : colors.surfaceRaised, buttonIcons: HugeIcons.strokeRoundedMoreHorizontalCircle02, buttonIconsSize: 26, iconColor: colors.textPrimary, onPressed: ..., wrap con OCLiquidGlassGroup(settings: const OCLiquidGlassSettings(refractStrength: -0.08, blurRadiusPx: 1.0, specStrength: 0, specWidth: 0.0, specAngle: 145, blendPx: 70, specPower: 10)));

9) Row con filtri / text input / voice input / keyboard
- Priorità: 1
- Problema: gli elementi dentro ai widget OCLiquidGlass della row con filtri, text input e voice input non si alzano e abbassano insieme ai widget che li wrappano; inoltre, quando si alzano hanno troppo margine rispetto alla tastiera, invece di stare appena sopra la tastiera.
- Problema correlato: quando la tastiera si chiude, gli input interni alla row scendono più dei widget glass, quindi gli input finiscono sotto il glass effect, che resta sopra.
- Richiesta: allineare correttamente il movimento di wrapper e contenuto, ridurre il margine rispetto alla tastiera e mantenere il glass e gli input sincronizzati in fase di apertura/chiusura della tastiera.

utilizzare questo tipo di ocliquid glass setting OCLiquidGlassGroup(
                    settings: const OCLiquidGlassSettings(
                      refractStrength: -0.08,
                      blurRadiusPx: 1.0,
                      specStrength: 0,
                      specWidth: 0.0,
                      specAngle: 145,
                      blendPx: 70,
                      specPower: 10,
                    ), nell app meccancio in modo da unfirmare tutte le trasparenze 
Conclusione
- KPI: priorità 1, perché impatta il corretto calcolo e la visibilità dei dati.
- Dropdown/work log history refresh non funzionante: priorità 2.
- Problemi grafici minori e resto: priorità 3.
