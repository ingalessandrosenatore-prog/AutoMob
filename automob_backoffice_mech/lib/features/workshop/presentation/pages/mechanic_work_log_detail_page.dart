import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

class MechanicWorkLogDetailPage extends StatelessWidget {
  const MechanicWorkLogDetailPage({required this.entry, super.key});

  final WorkLogEntry entry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AmThemeColors.of(context).background,
    body: SafeArea(
      top: true,
      bottom: false,
      child: WorkLogDetailBody(entry: entry),
    ),
  );
}
