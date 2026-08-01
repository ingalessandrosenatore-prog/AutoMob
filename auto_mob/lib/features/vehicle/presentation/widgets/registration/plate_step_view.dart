import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
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
    final targa = _targaController.text
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (!RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$').hasMatch(targa)) {
      showAmStatusDialog<void>(
        context,
        icon: HugeIcons.strokeRoundedAlert02,
        iconColor: const Color(0xFFFFB020),
        title: 'Targa non valida',
        message: 'Inserisci una targa nel formato AA123AA.',
        actions: [
          AmDialogAction(
            label: 'Chiudi',
            color: const Color(0xFFE85A1A),
            filled: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      return;
    }
    bloc.add(PlateSubmitted(targa: targa));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleRegistrationBloc, VehicleRegistrationState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep &&
          current.currentStep == 1,
      listener: (context, state) {
        _targaController.text = state.draft.targa ?? '';
        _submitted = false;
      },
      child: AmEdgeBlur(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  errorBuilder: (context, error, stackTrace) => const HugeIcon(
                    icon: HugeIcons.strokeRoundedWrench01,
                    color: _accent,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              BlocBuilder<VehicleRegistrationBloc, VehicleRegistrationState>(
                buildWhen: (previous, current) =>
                    previous.draft.meccanicoNome != current.draft.meccanicoNome,
                builder: (context, state) => Text(
                  state.draft.meccanicoNome == null
                      ? 'Registra il tuo veicolo'
                      : 'Benvenuto in ${state.draft.meccanicoNome}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Inserisci la targa del tuo veicolo e proveremo a recuperare i dati automaticamente.',
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
                    errorText:
                        _submitted &&
                            !RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$').hasMatch(
                              _targaController.text
                                  .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
                                  .toUpperCase(),
                            )
                        ? 'Formato richiesto: AA123AA'
                        : null,
                    height: 52,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
