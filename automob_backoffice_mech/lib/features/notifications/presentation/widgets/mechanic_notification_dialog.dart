import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/mechanic_notification.dart';
import '../bloc/mechanic_notification_cubit.dart';
import '../bloc/mechanic_notification_state.dart';
import 'notification_message_fields.dart';

Future<void> showMechanicNotificationDialog(
  BuildContext context, {
  required String vehicleName,
  required MechanicNotificationCubit Function() createCubit,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => BlocProvider(
    create: (_) => createCubit(),
    child: MechanicNotificationDialog(vehicleName: vehicleName),
  ),
);

class MechanicNotificationDialog extends StatelessWidget {
  const MechanicNotificationDialog({super.key, required this.vehicleName});
  final String vehicleName;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<MechanicNotificationCubit, MechanicNotificationState>(
    builder: (context, state) {
      final cubit = context.read<MechanicNotificationCubit>();
      final colors = AmThemeColors.of(context);
      final feedback =
          state.error ??
          switch (state.result) {
            NotificationSendResult.sent => 'Notifica inviata al proprietario.',
            NotificationSendResult.noDevice =>
              'Il proprietario non ha dispositivi abilitati alle notifiche. Nessun messaggio inviato.',
            NotificationSendResult.failed =>
              'Invio non riuscito. Nessun dispositivo ha accettato la notifica.',
            NotificationSendResult.pending =>
              'Esito dell’invio non ancora confermato. Premi “Verifica invio” per controllare senza inviare un duplicato.',
            null => null,
          };
      return PopScope(
        canPop: !state.sending,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AmStaticFrostedSurface(
              borderRadius: 28,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Avvisa il proprietario',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chiudi',
                          onPressed: state.sending
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              vehicleName,
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Tipo di intervento',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final type
                                    in MechanicNotificationType.values)
                                  ChoiceChip(
                                    label: Text(type.label),
                                    selected: state.type == type,
                                    onSelected: state.sending
                                        ? null
                                        : (_) => cubit.selectType(type),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            NotificationMessageFields(
                              state: state,
                              onTitleChanged: cubit.changeTitle,
                              onBodyChanged: cubit.changeBody,
                            ),
                            if (feedback != null) ...[
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  feedback,
                                  style: TextStyle(
                                    color:
                                        state.result ==
                                            NotificationSendResult.sent
                                        ? colors.textPrimary
                                        : colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: state.canSend ? cubit.send : null,
                              child: state.sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      state.result ==
                                              NotificationSendResult.pending
                                          ? 'Verifica invio'
                                          : 'Invia',
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
