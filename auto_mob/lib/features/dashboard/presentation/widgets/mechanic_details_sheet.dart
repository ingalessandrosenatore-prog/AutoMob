import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/connect_mechanic_cubit.dart';
import '../bloc/disconnect_mechanic_cubit.dart';

class MechanicDetailsPopUp<T> extends Page<T> {
  final String vehicleId;
  final MechanicSummary? mechanic;
  final ConnectMechanicCubit Function() createCubit;
  final DisconnectMechanicCubit Function() createDisconnectCubit;

  const MechanicDetailsPopUp({
    super.key,
    required this.vehicleId,
    required this.mechanic,
    required this.createCubit,
    required this.createDisconnectCubit,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (_) => mechanic == null
          ? BlocProvider<ConnectMechanicCubit>(
              create: (_) => createCubit(),
              child: _ConnectMechanicContent(vehicleId: vehicleId),
            )
          : BlocProvider<DisconnectMechanicCubit>(
              create: (_) => createDisconnectCubit(),
              child: _MechanicDetailsContent(
                vehicleId: vehicleId,
                mechanic: mechanic!,
              ),
            ),
    );
  }
}

class _ConnectMechanicContent extends StatefulWidget {
  final String vehicleId;

  const _ConnectMechanicContent({required this.vehicleId});

  @override
  State<_ConnectMechanicContent> createState() =>
      _ConnectMechanicContentState();
}

class _ConnectMechanicContentState extends State<_ConnectMechanicContent> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<ConnectMechanicCubit>().submit(vehicleId: widget.vehicleId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final mediaSize = MediaQuery.sizeOf(context);
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final maxModalHeight =
        (mediaSize.height - keyboardHeight - topSafeArea - 12)
            .clamp(0.0, mediaSize.height)
            .toDouble();

    return BlocConsumer<ConnectMechanicCubit, ConnectMechanicState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ConnectMechanicStatus.success:
            showAmStatusDialog<void>(
              context,
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              iconColor: const Color(0xFF30D158),
              title: 'Meccanico collegato',
              message:
                  '${state.mechanic?.businessName ?? 'La tua officina'} è ora collegata al veicolo.',
              actions: [
                AmDialogAction(
                  label: 'Fatto',
                  color: colors.accent,
                  filled: true,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
            break;
          case ConnectMechanicStatus.failure:
            showAmStatusDialog<void>(
              context,
              icon: HugeIcons.strokeRoundedAlert01,
              iconColor: colors.danger,
              title: 'Collegamento non riuscito',
              message: state.error,
              actions: [
                AmDialogAction(
                  label: 'Riprova',
                  color: colors.accent,
                  filled: true,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            );
            break;
          case ConnectMechanicStatus.initial:
          case ConnectMechanicStatus.loading:
            break;
        }
      },
      builder: (context, state) {
        final loading = state.status == ConnectMechanicStatus.loading;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxModalHeight),
            child: _SheetSurface(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetHeader(
                      title: 'Collega meccanico',
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 30),
                    const _MechanicAvatar(
                      icon: HugeIcons.strokeRoundedUserAdd01,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Aggiungi il tuo meccanico di fiducia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inserisci il codice fornito dalla tua officina per collegarla a questo veicolo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        AmTextField(
                          label: 'Codice meccanico',
                          placeholder: 'Inserisci il codice',
                          controller: _codeController,
                          isRequired: true,
                          obscureText: false,
                          keyboardType: TextInputType.text,
                          onChanged: (value) => context
                              .read<ConnectMechanicCubit>()
                              .codeChanged(value.toString()),
                          onEditingComplete: state.canSubmit ? _submit : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _ConnectCircleButton(
                      enabled: state.canSubmit,
                      loading: loading,
                      onTap: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MechanicDetailsContent extends StatelessWidget {
  final String vehicleId;
  final MechanicSummary mechanic;

  const _MechanicDetailsContent({
    required this.vehicleId,
    required this.mechanic,
  });

  Future<void> _call(BuildContext context) async {
    final phone = mechanic.phone;
    if (phone == null) return;

    final launched = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile avviare la chiamata.')),
      );
    }
  }

  void _confirmDisconnect(BuildContext context) {
    final colors = AmThemeColors.of(context);
    showAmStatusDialog<void>(
      context,
      icon: HugeIcons.strokeRoundedDelete02,
      iconColor: colors.danger,
      title: 'Scollega officina',
      message:
          'Vuoi scollegare ${mechanic.businessName} da questo veicolo? I lavori gia registrati resteranno nello storico.',
      actions: [
        AmDialogAction(
          label: 'Annulla',
          color: colors.textSecondary,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        AmDialogAction(
          label: 'Scollega',
          color: colors.danger,
          filled: true,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.read<DisconnectMechanicCubit>().submit(
              vehicleId: vehicleId,
              mechanicId: mechanic.id,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final phone = mechanic.phone;

    return BlocConsumer<DisconnectMechanicCubit, DisconnectMechanicState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case DisconnectMechanicStatus.success:
            showAmStatusDialog<void>(
              context,
              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
              iconColor: const Color(0xFF30D158),
              title: 'Officina scollegata',
              message:
                  '${mechanic.businessName} non e piu collegata al veicolo.',
              actions: [
                AmDialogAction(
                  label: 'Fatto',
                  color: colors.accent,
                  filled: true,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          case DisconnectMechanicStatus.failure:
            showAmStatusDialog<void>(
              context,
              icon: HugeIcons.strokeRoundedAlert01,
              iconColor: colors.danger,
              title: 'Scollegamento non riuscito',
              message: state.error,
              actions: [
                AmDialogAction(
                  label: 'Chiudi',
                  color: colors.accent,
                  filled: true,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            );
          case DisconnectMechanicStatus.initial:
          case DisconnectMechanicStatus.loading:
            break;
        }
      },
      builder: (context, state) => _SheetSurface(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(
                title: 'Il tuo meccanico',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 30),
              const _MechanicAvatar(icon: HugeIcons.strokeRoundedWrench01),
              const SizedBox(height: 18),
              Text(
                mechanic.businessName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              _ContactRow(
                icon: Icons.location_on_outlined,
                label: 'Indirizzo',
                value: mechanic.address ?? 'Non disponibile',
              ),
              const SizedBox(height: 12),
              _ContactRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: mechanic.email ?? 'Non disponibile',
              ),
              const SizedBox(height: 28),
              Semantics(
                button: phone != null,
                label: phone == null
                    ? 'Numero di telefono non disponibile'
                    : 'Chiama $phone',
                child: GestureDetector(
                  onTap: phone == null ? null : () => _call(context),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(
                        alpha: phone == null ? 0.32 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          color: phone == null
                              ? colors.textSecondary
                              : colors.onMedia,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          phone ?? 'Telefono non disponibile',
                          style: TextStyle(
                            color: phone == null
                                ? colors.textSecondary
                                : colors.onMedia,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                button: state.status != DisconnectMechanicStatus.loading,
                label: 'Scollega ${mechanic.businessName}',
                child: GestureDetector(
                  key: const Key('disconnect_mechanic_button'),
                  onTap: state.status == DisconnectMechanicStatus.loading
                      ? null
                      : () => _confirmDisconnect(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.danger.withValues(alpha: 0.45),
                      ),
                    ),
                    child: state.status == DisconnectMechanicStatus.loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: colors.danger,
                              strokeWidth: 2.3,
                            ),
                          )
                        : Text(
                            'SCOLLEGA OFFICINA',
                            style: TextStyle(
                              color: colors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSurface extends StatelessWidget {
  final Widget child;

  const _SheetSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.border)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.info.withValues(alpha: 0.35)),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: colors.info,
              size: 20,
              strokeWidth: 2.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _MechanicAvatar extends StatelessWidget {
  final List<List> icon;

  const _MechanicAvatar({required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: colors.info.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: colors.info,
          size: 40,
          strokeWidth: 2.2,
        ),
      ),
    );
  }
}

class _ConnectCircleButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _ConnectCircleButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Semantics(
      button: enabled,
      label: 'Collega meccanico',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: const Key('connect_mechanic_button'),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: enabled ? 1 : 0.32),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: loading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: colors.onMedia,
                        strokeWidth: 2.5,
                      ),
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedUserAdd01,
                      color: enabled ? colors.onMedia : colors.textSecondary,
                      size: 30,
                      strokeWidth: 2.2,
                    ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'COLLEGA',
            style: TextStyle(
              color: enabled ? colors.accent : colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.info, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
