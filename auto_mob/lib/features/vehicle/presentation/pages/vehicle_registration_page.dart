import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../../../../core/config/performance_flags.dart';
import '../../../../core/widgets/buttons/soft_button.dart';
import '../bloc/vehicle_registration_bloc.dart';
import '../bloc/vehicle_registration_event.dart';
import '../bloc/vehicle_registration_state.dart';
import '../widgets/registration/mechanic_step_view.dart';
import '../widgets/registration/photo_step_view.dart';
import '../widgets/registration/plate_step_view.dart';
import '../widgets/registration/verify_step_view.dart';
import '../widgets/registration/vehicle_registration_close_dialog.dart';
import '../widgets/registration/work_log_step_view.dart';

const _stepLabels = ['Meccanico', 'Targa', 'Verifica', 'Lavori', 'Foto'];
const _arancione = Color(0xFFE85A1A);

/// Pagina full-screen di registrazione veicolo (rework del vecchio pop-up
/// `AddVehicleWizard`). Solo front-end per ora: nessun salvataggio reale,
/// la navigazione tra step e' gestita da VehicleRegistrationBloc.
class VehicleRegistrationPage extends StatelessWidget {
  /// Come chiudere la pagina. `null` → `context.pop()` (apertura via route
  /// classica). Quando la pagina vive dentro una transizione custom (es.
  /// LiquidZoom) il chiamante DEVE passare qui il suo `close`: un pop diretto
  /// salterebbe l'animazione di chiusura lasciando il trigger nascosto.
  final VoidCallback? onClose;

  const VehicleRegistrationPage({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocProvider(
      create: (_) =>
          GetIt.I<VehicleRegistrationBloc>()..add(RegistrationStarted()),
      child: Scaffold(
        backgroundColor: colors.background,
        // La tastiera non deve spostare la bottom bar: l'inset viene
        // applicato esclusivamente al PageView in _RegistrationBody.
        resizeToAvoidBottomInset: false,
        body: _RegistrationBody(onClose: onClose),
      ),
    );
  }
}

class _RegistrationBody extends StatefulWidget {
  final VoidCallback? onClose;

  const _RegistrationBody({this.onClose});

  @override
  State<_RegistrationBody> createState() => _RegistrationBodyState();
}

class _RegistrationBodyState extends State<_RegistrationBody> {
  late final PageController _pageController;

  void _closeNow({bool success = false}) {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      context.pop(success);
    }
  }

  Future<void> _chiudi() async {
    final bloc = context.read<VehicleRegistrationBloc>();
    if (bloc.state.status == RegistrationStatus.completed ||
        (bloc.state.currentStep == 0 && bloc.state.draft.targa == null)) {
      _closeNow();
      return;
    }
    final action = await showVehicleRegistrationCloseDialog(context);
    if (!mounted || action == null) return;
    if (action == VehicleRegistrationCloseAction.discardDraft) {
      bloc.add(RegistrationDraftDiscarded());
    } else {
      bloc.add(RegistrationDraftSaveRequested());
    }
    _closeNow();
  }

  Future<void> _showLookupDialog(VehicleRegistrationState state) async {
    if (state.lookupStatus == RegistrationLookupStatus.partial) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          title: const Text('Dati recuperati parzialmente'),
          content: const Text(
            'Alcuni dati non sono disponibili. Controlla e completa i campi prima di continuare.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Visualizza dati'),
            ),
          ],
        ),
      );
      if (mounted) {
        context.read<VehicleRegistrationBloc>().add(LookupDialogAcknowledged());
      }
      return;
    }
    final failure = state.lookupFailure;
    if (state.lookupStatus != RegistrationLookupStatus.failure ||
        failure == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.redAccent),
        title: const Text('Dati non recuperati'),
        content: Text(failure.message),
        actions: [
          if (failure.isRetryable)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<VehicleRegistrationBloc>().add(
                  PlateSubmitted(targa: state.draft.targa ?? ''),
                );
              },
              child: const Text('Riprova'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<VehicleRegistrationBloc>().add(
                LookupClosedWithManualEntry(),
              );
            },
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMechanicDialog(VehicleRegistrationState state) async {
    if (state.mechanicStatus != MechanicLookupStatus.notFound &&
        state.mechanicStatus != MechanicLookupStatus.failure) {
      return;
    }
    await showAmStatusDialog<void>(
      context,
      icon: HugeIcons.strokeRoundedAlert02,
      iconColor: const Color(0xFFFFB020),
      title: 'Codice meccanico non valido',
      message:
          state.message ?? 'Controlla il codice inserito e prova nuovamente.',
      actions: [
        AmDialogAction(
          label: 'Chiudi',
          color: const Color(0xFFE85A1A),
          filled: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _showRegistrationResult(VehicleRegistrationState state) async {
    if (state.status == RegistrationStatus.failure) {
      await showAmStatusDialog<void>(
        context,
        icon: HugeIcons.strokeRoundedAlert02,
        iconColor: const Color(0xFFFF453A),
        title: 'Registrazione non riuscita',
        message: state.message ?? 'Non e stato possibile salvare il veicolo.',
        actions: [
          AmDialogAction(
            label: 'Chiudi',
            color: const Color(0xFFFF453A),
            filled: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      return;
    }
    if (state.status != RegistrationStatus.completed) return;
    final closeRegistration = await showAmStatusDialog<bool>(
      context,
      icon: HugeIcons.strokeRoundedValidationApproval,
      iconColor: const Color(0xFF34C759),
      title: 'Veicolo registrato',
      message: state.photoWarning
          ? 'Il veicolo e stato salvato, ma la foto non e stata copiata. Potrai aggiungerla dalla dashboard.'
          : 'Dati, lavori iniziali e collegamento al meccanico sono stati salvati.',
      actions: [
        AmDialogAction(
          label: 'Chiudi',
          color: const Color(0xFF34C759),
          filled: true,
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
    if (mounted && closeRegistration == true) {
      _closeNow(success: true);
    }
  }

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
      listenWhen: (prev, curr) =>
          prev.currentStep != curr.currentStep ||
          prev.lookupStatus != curr.lookupStatus ||
          prev.mechanicStatus != curr.mechanicStatus ||
          prev.status != curr.status,
      listener: (context, state) async {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            state.currentStep,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
          );
        }
        await _showLookupDialog(state);
        if (!context.mounted) return;
        await _showMechanicDialog(state);
        if (!context.mounted) return;
        await _showRegistrationResult(state);
      },
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.currentStep != curr.currentStep ||
          prev.lookupStatus != curr.lookupStatus,
      builder: (context, state) {
        final colors = AmThemeColors.of(context);
        if (state.status == RegistrationStatus.completed) {
          return _RegistrationCompletedView(
            onClose: () => _closeNow(success: true),
            photoWarning: state.photoWarning,
          );
        }
        final closeButton = SizedBox(
          width: 48,
          height: 48,
          child: AmSoftButton(
            width: 48,
            height: 48,
            color: colors.surface,
            colorOpacity: 0.2,
            iconColor: colors.textPrimary,
            icon: HugeIcons.strokeRoundedArrowLeft01,
            onPressed: _chiudi,
          ),
        );
        final topInset = MediaQuery.paddingOf(context).top;
        final keyboardOverlap = math.max(
          0.0,
          MediaQuery.viewInsetsOf(context).bottom -
              _RegistrationBottomBar.extent(context),
        );
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
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: kHeavyEffects
                            ? OCLiquidGlassGroup(
                                settings: const OCLiquidGlassSettings(
                                  refractStrength: -0.13,
                                  blurRadiusPx: 1.0,
                                  specStrength: 0,
                                  specWidth: 0,
                                  specAngle: 145,
                                  blendPx: 20,
                                  specPower: 10,
                                ),
                                child: closeButton,
                              )
                            : closeButton,
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
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(width: 48, height: 48),
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
              child: Padding(
                // La barra resta nella sua posizione originale (e viene
                // coperta dalla tastiera). Si restringe soltanto il viewport
                // delle pagine per la porzione di tastiera che lo interseca.
                padding: EdgeInsets.only(bottom: keyboardOverlap),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _steps,
                ),
              ),
            ),
            _RegistrationBottomBar(
              currentStep: state.currentStep,
              loading:
                  state.status == RegistrationStatus.loading ||
                  state.mechanicStatus == MechanicLookupStatus.loading ||
                  (state.currentStep == 1 &&
                      state.lookupStatus == RegistrationLookupStatus.loading),
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
    'COLLEGA MECCANICO',
    'TROVA VEICOLO',
    'CONTINUA',
    'CONTINUA',
    'REGISTRA',
  ];

  static double _bottomPadding(BuildContext context) =>
      math.max(20.0, MediaQuery.viewPaddingOf(context).bottom + 8);

  /// Spazio verticale gia' occupato sotto al PageView. Quando compare la
  /// tastiera, questa parte non va sottratta una seconda volta al contenuto.
  static double extent(BuildContext context) =>
      20 + 52 + _bottomPadding(context);

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final showBack = currentStep >= 1;
    final label = _labels[currentStep.clamp(0, _labels.length - 1)];
    final bottomPadding = _bottomPadding(context);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      // Altezza fissa e identica su tutti gli step: senza questo vincolo
      // il pulsante circolare e quello principale restano sempre allineati
      // anche durante l'animazione di comparsa di "Indietro".
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              width: showBack ? 52 : 0,
              margin: EdgeInsets.only(right: showBack ? 16 : 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showBack ? 1 : 0,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: AmIconButton(
                    width: 52,
                    height: 52,
                    radius: 26,
                    showShadow: true,
                    shadowColor: colors.shadow.withValues(alpha: 0.18),
                    shadowBlurRadius: 8,
                    shadowOffset: const Offset(0, 3),
                    backgroundColor: colors.surface,
                    iconColor: colors.accent,
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    iconTurns: 0.5,
                    iconSize: 28,
                    strokeWidth: 2.2,
                    tooltip: 'Indietro',
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
  final VoidCallback onClose;
  final bool photoWarning;

  const _RegistrationCompletedView({
    required this.onClose,
    required this.photoWarning,
  });

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
              photoWarning
                  ? 'Il veicolo è salvato. Non è stato possibile copiare la foto: potrai aggiungerla dalla dashboard.'
                  : 'Dati, storico iniziale e collegamento al meccanico sono stati salvati.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onClose,
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
