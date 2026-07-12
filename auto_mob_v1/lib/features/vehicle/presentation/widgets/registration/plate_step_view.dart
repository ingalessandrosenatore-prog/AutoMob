import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../../core/widgets/input/textfield.dart';
import '../../bloc/vehicle_registration_bloc.dart';
import '../../bloc/vehicle_registration_event.dart';
import '../../bloc/vehicle_registration_state.dart';

const String _logoOfficinaDefault =
    'lib/assets/images/logo_officina_giordano.png';
const _accent = Color(0xFFE85A1A);

/// Step 2 — targa del veicolo: avatar dell'officina/meccanico collegato +
/// benvenuto + campo targa + "Trova veicolo" (lookup mock).
///
/// Il bottone vive nella barra fissa della pagina root
/// ([VehicleRegistrationPage]): questo widget espone [submit] tramite
/// `GlobalKey<PlateStepViewState>`.
class PlateStepView extends StatefulWidget {
  const PlateStepView({super.key});

  @override
  State<PlateStepView> createState() => PlateStepViewState();
}

class PlateStepViewState extends State<PlateStepView> {
  final _targaController = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<VehicleRegistrationBloc>().state.draft;
    if (draft.targa != null) _targaController.text = draft.targa!;
  }

  @override
  void dispose() {
    _targaController.dispose();
    super.dispose();
  }

  void submit() {
    final bloc = context.read<VehicleRegistrationBloc>();
    if (bloc.state.lookupStatus == RegistrationLookupStatus.loading) return;
    setState(() => _submitted = true);
    final targa = _targaController.text.trim();
    if (targa.isEmpty) return;
    bloc.add(PlateSubmitted(targa: targa));
  }

  @override
  Widget build(BuildContext context) {
    return AmEdgeBlur(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                shape: BoxShape.circle,
                border: Border.all(color: _accent, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                _logoOfficinaDefault,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.build_circle_outlined,
                  color: _accent,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Benvenuto in Autofficina Giordano',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Inserisci la targa del tuo veicolo e recupereremo tutti i dati.',
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
                  label: 'Targa',
                  placeholder: 'AB 123 CD',
                  controller: _targaController,
                  isRequired: true,
                  obscureText: false,
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                  errorText: _submitted && _targaController.text.trim().isEmpty
                      ? 'Campo obbligatorio'
                      : null,
                  height: 52,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
