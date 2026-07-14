import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/buttons/back_button.dart';
import '../../../../core/theme/am_theme_colors.dart';
import '../../../../core/widgets/buttons/fab_princ.dart';
import '../../../../core/widgets/buttons/soft_button.dart';
import '../../../../core/widgets/hero/am_fab_hero.dart';
import '../../../../core/widgets/progress/am_wizard_progress.dart';
import '../bloc/vehicle_registration_bloc.dart';
import '../bloc/vehicle_registration_event.dart';
import '../bloc/vehicle_registration_state.dart';
import '../widgets/registration/mechanic_step_view.dart';
import '../widgets/registration/photo_step_view.dart';
import '../widgets/registration/plate_step_view.dart';
import '../widgets/registration/verify_step_view.dart';
import '../widgets/registration/work_log_step_view.dart';

const _stepLabels = ['Meccanico', 'Targa', 'Verifica', 'Lavori', 'Foto'];
const _arancione = Color(0xFFE85A1A);

/// Pagina full-screen di registrazione veicolo (rework del vecchio pop-up
/// `AddVehicleWizard`). Solo front-end per ora: nessun salvataggio reale,
/// la navigazione tra step e' gestita da VehicleRegistrationBloc.
class VehicleRegistrationPage extends StatelessWidget {
  const VehicleRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocProvider(
      create: (_) =>
          GetIt.I<VehicleRegistrationBloc>()..add(RegistrationStarted()),
      child: Scaffold(
        backgroundColor: colors.background,
        // I bottoni in basso restano fissi anche quando si apre la
        // tastiera (niente "salita" insieme ad essa).
        resizeToAvoidBottomInset: false,
        body: const _RegistrationBody(),
      ),
    );
  }
}

class _RegistrationBody extends StatefulWidget {
  const _RegistrationBody();

  @override
  State<_RegistrationBody> createState() => _RegistrationBodyState();
}

class _RegistrationBodyState extends State<_RegistrationBody> {
  late final PageController _pageController;

  // GlobalKey tipizzate sullo State pubblico di ogni step: permettono alla
  // barra pulsanti FISSA (vive qui, non dentro i singoli step) di invocarne
  // il submit senza dover ricreare i bottoni ad ogni cambio pagina.
  final _mechanicKey = GlobalKey<MechanicStepViewState>();
  final _plateKey = GlobalKey<PlateStepViewState>();
  final _verifyKey = GlobalKey<VerifyStepViewState>();
  final _workLogKey = GlobalKey<WorkLogStepViewState>();
  final _photoKey = GlobalKey<PhotoStepViewState>();

  late final List<Widget> _steps = [
    MechanicStepView(key: _mechanicKey),
    PlateStepView(key: _plateKey),
    VerifyStepView(key: _verifyKey),
    WorkLogStepView(key: _workLogKey),
    PhotoStepView(key: _photoKey),
  ];

  @override
  void initState() {
    super.initState();
    final initialStep = context
        .read<VehicleRegistrationBloc>()
        .state
        .currentStep;
    _pageController = PageController(initialPage: initialStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleMainPressed(int step) {
    switch (step) {
      case 0:
        _mechanicKey.currentState?.submit();
      case 1:
        _plateKey.currentState?.submit();
      case 2:
        _verifyKey.currentState?.submit();
      case 3:
        _workLogKey.currentState?.submit();
      case 4:
        _photoKey.currentState?.submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VehicleRegistrationBloc, VehicleRegistrationState>(
      listenWhen: (prev, curr) => prev.currentStep != curr.currentStep,
      listener: (context, state) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
          );
        }
      },
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.currentStep != curr.currentStep ||
          prev.lookupStatus != curr.lookupStatus,
      builder: (context, state) {
        final colors = AmThemeColors.of(context);
        if (state.status == RegistrationStatus.completed) {
          return const _RegistrationCompletedView();
        }
        final topInset = MediaQuery.paddingOf(context).top;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(width: 45, height: 45),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            "REGISTRA VEICOLO",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: colors.textPrimary,
                              shadows: [
                                Shadow(
                                  color: colors.shadow.withValues(alpha: 0.22),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AmFabHero(
                          child: SizedBox(
                            width: 45,
                            height: 45,
                          child: AmSoftButton(
                            width: 45,
                            height: 45,
                            color: const Color(0xFFFF6B00),
                            icon: HugeIcons.strokeRoundedAdd01,
                            iconTurns: 0.125,
                            onPressed: () => context.pop(),
                          ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AmWizardProgress(
              steps: _stepLabels,
              currentStep: state.currentStep,
              color: _arancione,
              indicatorAsset: 'lib/assets/icons/car_red.svg',
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _steps,
              ),
            ),
            _RegistrationBottomBar(
              currentStep: state.currentStep,
              loading:
                  state.currentStep == 1 &&
                  state.lookupStatus == RegistrationLookupStatus.loading,
              onBack: () => context.read<VehicleRegistrationBloc>().add(
                RegistrationStepBackPressed(),
              ),
              onMainPressed: () => _handleMainPressed(state.currentStep),
            ),
          ],
        );
      },
    );
  }
}

/// Barra pulsanti fissa: NON viene ricreata ad ogni cambio step (a
/// differenza di prima, quando ogni step aveva i propri bottoni). Quando si
/// passa da uno step "singolo" (solo bottone principale, es. Targa) a uno
/// "doppio" (Indietro + principale, es. Verifica) e viceversa, "Indietro"
/// scorre/appare in dissolvenza mentre il bottone principale si
/// restringe/allarga di conseguenza; la label del bottone principale cambia
/// con un fade.
class _RegistrationBottomBar extends StatelessWidget {
  final int currentStep;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onMainPressed;

  const _RegistrationBottomBar({
    required this.currentStep,
    required this.loading,
    required this.onBack,
    required this.onMainPressed,
  });

  static const _labels = [
    'CONTINUA',
    'TROVA VEICOLO',
    'CONTINUA',
    'CONTINUA',
    'CONTINUA',
  ];

  @override
  Widget build(BuildContext context) {
    final showBack = currentStep >= 2;
    final label = _labels[currentStep.clamp(0, _labels.length - 1)];

    return Container(
      padding: const EdgeInsets.all(20),
      // Altezza fissa e identica su tutti gli step: senza questo vincolo
      // "Indietro" (un OutlinedButton con padding proprio, leggermente piu'
      // alto di AmMainFab) puo' far variare l'altezza della riga anche
      // quando e' nascosto a larghezza zero.
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              width: showBack ? 130 : 0,
              margin: EdgeInsets.only(right: showBack ? 16 : 0),
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showBack ? 1 : 0,
                child: SizedBox(
                  width: 130,
                  height: 52,
                  child: AmOutlinedButton(
                    label: 'INDIETRO',
                    color: const Color(0xFFE85A1A),
                    fillColor: Colors.transparent,
                    onPressed: onBack,
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: AmMainFab(
                  key: ValueKey(label),
                  label: label,
                  height: 52,
                  width: double.infinity,
                  color: const Color(0xFFE85A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  isLoading: loading,
                  onPressed: onMainPressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationCompletedView extends StatelessWidget {
  const _RegistrationCompletedView();

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedValidationApproval,
              color: Color(0xFF34C759),
              size: 64,
              strokeWidth: 2.2,
            ),
            const SizedBox(height: 20),
            Text(
              'Veicolo registrato',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Solo anteprima front-end: nessun dato e\' stato ancora salvato.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Chiudi',
                style: TextStyle(color: Color(0xFF4A90E2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
