import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../../core/widgets/input/textfield.dart';
import '../../bloc/vehicle_registration_bloc.dart';
import '../../bloc/vehicle_registration_event.dart';
import '../../bloc/vehicle_registration_state.dart';

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
    final colors = AmThemeColors.of(context);
    return AmEdgeBlur(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAgreement01,
              color: Color(0xFFE85A1A),
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              'Meccanico di fiducia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Inserisci il codice del tuo meccanico di fiducia per collegarlo '
              'al tuo veicolo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
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
            BlocBuilder<VehicleRegistrationBloc, VehicleRegistrationState>(
              builder: (context, state) => Column(
                children: [
                  TextButton(
                    onPressed:
                        state.mechanicStatus == MechanicLookupStatus.loading
                        ? null
                        : () => context.read<VehicleRegistrationBloc>().add(
                            RegistrationWithoutMechanicPressed(),
                          ),
                    child: Text(
                      'Non ho un meccanico',
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
