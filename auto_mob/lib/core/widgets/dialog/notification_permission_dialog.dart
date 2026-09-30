import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

/// Dialogo introduttivo mostrato prima del popup nativo Android/iOS.
/// Spiegare il motivo prima di chiedere il permesso riduce i rifiuti casuali.
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({
    super.key,
    required this.onPostpone,
    required this.onEnable,
  });

  final VoidCallback onPostpone;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return AmStatusDialog(
      icon: HugeIcons.strokeRoundedNotification01,
      iconColor: const Color(0xFFFF6B00),
      title: 'Prenditi cura della tua auto',
      message:
          'Attiva i promemoria AutoMob per ricordare chilometri, '
          'manutenzione e revisione.',
      actions: [
        AmDialogAction(
          label: 'Non ora',
          color: const Color(0xFF8E8E93),
          onPressed: onPostpone,
        ),
        AmDialogAction(
          label: 'Attiva',
          color: const Color(0xFFFF6B00),
          filled: true,
          onPressed: onEnable,
        ),
      ],
    );
  }
}

Future<T?> showNotificationPermissionDialog<T>(
  BuildContext context, {
  required VoidCallback onPostpone,
  required VoidCallback onEnable,
}) => showDialog<T>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      NotificationPermissionDialog(onPostpone: onPostpone, onEnable: onEnable),
);
