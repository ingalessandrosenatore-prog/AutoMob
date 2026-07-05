import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../bloc/add_vehicle_bloc.dart';
import '../bloc/add_vehicle_event.dart';
import '../bloc/add_vehicle_state.dart';
import 'add_vehicle_form_step1.dart';
import 'add_vehicle_form_step2.dart';
import 'add_vehicle_form_step3.dart';
import 'add_vehicle_form_step4.dart';
import 'add_vehicle_form_step5.dart';

class AddVehicleWizard extends StatelessWidget {
  const AddVehicleWizard({super.key});

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.75;
    return BlocProvider(
      create: (_) => GetIt.I<AddVehicleBloc>()..add(AddVehicleStarted()),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: sheetHeight,
          minHeight: sheetHeight,
        ),
        child: const WizardBody(),
      ),
    );
  }
}

class WizardBody extends StatefulWidget {
  const WizardBody({super.key});

  @override
  State<WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends State<WizardBody> {
  late final PageController _pageController;

  // Ordine: 1) dati base, 2) dati tecnici + KM ATTUALI, 3) storico manutenzioni,
  // 4) scadenze/gomme, 5) foto/meccanico. I km attuali sono chiesti come 2° step
  // cosi' negli step successivi possiamo validare che gli "ultimo km" non li superino.
  static const _steps = [
    AddVehicleFormStep1(key: ValueKey(0)),
    AddVehicleFormStep3(key: ValueKey(1)), // dati tecnici + km attuali
    AddVehicleFormStep2(key: ValueKey(2)), // storico manutenzioni
    AddVehicleFormStep4(key: ValueKey(3)),
    AddVehicleFormStep5(key: ValueKey(4)),
  ];

  @override
  void initState() {
    super.initState();
    final initialStep = context.read<AddVehicleBloc>().state.currentStep;
    _pageController = PageController(initialPage: initialStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddVehicleBloc, AddVehicleState>(
      listenWhen: (prev, curr) =>
          prev.currentStep != curr.currentStep || prev.status != curr.status,
      listener: (context, state) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
          );
        }
      },
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        if (state.status == AddVehicleStatus.completed) {
          return _WizardCompletedPage(draft: state.draft);
        }
        if (state.status == AddVehicleStatus.error) {
          return _WizardErrorPage(message: state.errorMessage ?? 'Errore sconosciuto');
        }
        // Il PageView resta SEMPRE montato: il loading è solo un overlay,
        // così il PageController non perde i client e l'animazione tra step
        // (listener -> animateToPage) non viene mai saltata.
        return Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _steps,
            ),
            if (state.status == AddVehicleStatus.loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFE85A1A)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WizardCompletedPage extends StatelessWidget {
  final VehicleDraft draft;
  const _WizardCompletedPage({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF34C759), size: 28),
              SizedBox(width: 12),
              Text(
                'Veicolo salvato',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Dati salvati in locale (SharedPreferences):',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _DraftRow(label: 'Marca', value: draft.marca),
          _DraftRow(label: 'Modello', value: draft.modello),
          _DraftRow(label: 'Anno', value: draft.anno?.toString()),
          _DraftRow(label: 'Carburante', value: draft.carburante),
          _DraftRow(label: 'Targa', value: draft.targa),
          const Divider(color: Color(0xFF1C1C1E), height: 24),

          _DraftRow(label: 'Km ult. tagliando', value: draft.kmUltimoTagliando?.toString()),

          _DraftRow(label: 'Km ult. distribuzione', value: draft.kmUltimaDistribuzione?.toString()),
          const Divider(color: Color(0xFF1C1C1E), height: 24),
          _DraftRow(label: 'Potenza (CV)', value: draft.potenzaCv?.toString()),
          _DraftRow(label: 'Cilindrata', value: draft.cilindrata?.toString()),
          _DraftRow(label: 'Km attuali', value: draft.kmAttuali?.toString()),
          const Divider(color: Color(0xFF1C1C1E), height: 24),
          _DraftRow(label: 'Prossima revisione', value: _fmtDate(draft.prossimarevisione)),
          _DraftRow(label: 'Km ult. cambio gomme', value: draft.kmUltimoCambioGomme?.toString()),
          _DraftRow(label: 'Intervallo cambio gomme', value: draft.intervalloCambioGomme?.toString()),
          _DraftRow(label: 'Km ult. inversione', value: draft.kmUltimaInversioneGomme?.toString()),
          _DraftRow(label: 'Intervallo inversione', value: draft.intervalloInversioneGomme?.toString()),
          const Divider(color: Color(0xFF1C1C1E), height: 24),
          _DraftRow(label: 'Foto path', value: draft.fotoFile?.path),
          _DraftRow(label: 'Codice meccanico', value: draft.codiceMeccanico),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi', style: TextStyle(color: Color(0xFF4A90E2))),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _DraftRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DraftRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value == null || (value?.isEmpty ?? true) ? '—' : value!,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardErrorPage extends StatelessWidget {
  final String message;
  const _WizardErrorPage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF453A), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Errore di salvataggio',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi', style: TextStyle(color: Color(0xFF4A90E2))),
          ),
        ],
      ),
    );
  }
}
