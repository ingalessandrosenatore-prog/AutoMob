import 'package:flutter/material.dart';
import '../bloc/mechanic_notification_state.dart';

class NotificationMessageFields extends StatefulWidget {
  const NotificationMessageFields({
    super.key,
    required this.state,
    required this.onTitleChanged,
    required this.onBodyChanged,
  });
  final MechanicNotificationState state;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onBodyChanged;

  @override
  State<NotificationMessageFields> createState() =>
      _NotificationMessageFieldsState();
}

class _NotificationMessageFieldsState extends State<NotificationMessageFields> {
  late final _title = TextEditingController(text: widget.state.title);
  late final _body = TextEditingController(text: widget.state.body);

  @override
  void didUpdateWidget(covariant NotificationMessageFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only replace controller values when the selected template changes;
    // ordinary typing keeps its cursor and IME composition intact.
    if (_title.text != widget.state.title) _title.text = widget.state.title;
    if (_body.text != widget.state.body) _body.text = widget.state.body;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        key: const Key('notification-title'),
        controller: _title,
        enabled: !widget.state.sending,
        minLines: 1,
        maxLines: 2,
        maxLength: 100,
        decoration: const InputDecoration(
          labelText: 'Titolo',
          border: OutlineInputBorder(),
        ),
        onChanged: widget.onTitleChanged,
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('notification-body'),
        controller: _body,
        enabled: !widget.state.sending,
        minLines: 3,
        maxLines: 5,
        maxLength: 500,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          labelText: 'Messaggio',
          border: OutlineInputBorder(),
        ),
        onChanged: widget.onBodyChanged,
      ),
    ],
  );
}
