import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../../core/widgets/input/textfield.dart';
import '../../bloc/vehicle_registration_bloc.dart';
import '../../bloc/vehicle_registration_event.dart';

/// Step 1 — codice del meccanico di fiducia (opzionale). Per ora solo il
/// percorso "ho un meccanico" e' abilitato: il bottone "Non ho meccanico"
/// resta visibile ma disattivato (mock, in attesa di un vero servizio di
/// ricerca officine).
///
/// Il bottone "Continua" vive nella barra fissa della pagina root
/// ([VehicleRegistrationPage]), non qui: questo widget espone [submit]
/// tramite `GlobalKey<MechanicStepViewState>` cosi' i bottoni non vengono
/// piu' ricreati (e "saltano" visivamente) ad ogni cambio step.
class MechanicStepView extends StatefulWidget {
  const MechanicStepView({super.key});

  @override
  State<MechanicStepView> createState() => MechanicStepViewState();
}

class MechanicStepViewState extends State<MechanicStepView> {
  final _codiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = context.read<VehicleRegistrationBloc>().state.draft;
    if (draft.codiceMeccanico != null) {
      _codiceController.text = draft.codiceMeccanico!;
    }
  }

  @override
  void dispose() {
    _codiceController.dispose();
    super.dispose();
  }

  void submit() {
    context.read<VehicleRegistrationBloc>().add(
      MechanicStepSubmitted(
        codiceMeccanico: _codiceController.text.trim().isEmpty
            ? null
            : _codiceController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AmEdgeBlur(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.handshake_outlined,
              color: Color(0xFFE85A1A),
              size: 56,
            ),
            const SizedBox(height: 20),
            const Text(
              'Meccanico di fiducia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Inserisci il codice del tuo meccanico di fiducia per collegarlo '
              'al tuo veicolo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                AmTextField(
                  label: 'Codice meccanico',
                  placeholder: 'MECH-XXXX',
                  controller: _codiceController,
                  isRequired: false,
                  obscureText: false,
                  keyboardType: TextInputType.text,
                  height: 52,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: 0.4,
              child: IgnorePointer(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Non ho un meccanico',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
