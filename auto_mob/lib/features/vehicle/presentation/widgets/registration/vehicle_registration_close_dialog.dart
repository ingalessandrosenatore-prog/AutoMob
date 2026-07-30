import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/widgets/dialog/am_status_dialog.dart';

/// Scelta esplicita effettuata quando l'utente chiude la registrazione.
enum VehicleRegistrationCloseAction { saveDraft, discardDraft }

/// Mostra il popup di uscita con lo stesso stile usato dagli altri messaggi
/// della registrazione. Il dialog non modifica lo stato: restituisce soltanto
/// la scelta, che viene poi trasformata nell'evento BLoC dalla pagina.
Future<VehicleRegistrationCloseAction?> showVehicleRegistrationCloseDialog(
  BuildContext context,
) {
  return showAmStatusDialog<VehicleRegistrationCloseAction>(
    context,
    icon: HugeIcons.strokeRoundedAlert02,
    iconColor: const Color(0xFFFFB020),
    title: 'Uscire dalla registrazione?',
    message:
        'Puoi salvare la bozza e riprendere in seguito senza perdere i dati inseriti.',
    actions: [
      AmDialogAction(
        label: 'Scarta e chiudi',
        color: const Color(0xFFFF453A),
        onPressed: () => Navigator.of(
          context,
        ).pop(VehicleRegistrationCloseAction.discardDraft),
      ),
      AmDialogAction(
        label: 'Salva draft e chiudi',
        color: const Color(0xFFE85A1A),
        filled: true,
        onPressed: () =>
            Navigator.of(context).pop(VehicleRegistrationCloseAction.saveDraft),
      ),
    ],
  );
}
