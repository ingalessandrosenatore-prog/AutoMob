import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../domain/work_log_entry.dart';
import 'work_log_bloc.dart';
import 'work_log_item_card.dart';

/// Variante sliver dello storico, per app che mantengono la propria AppBar.
class WorkLogHistorySliver extends StatelessWidget {
  const WorkLogHistorySliver({required this.onEntryPressed, super.key});

  final ValueChanged<WorkLogEntry> onEntryPressed;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkLogHistoryBloc, WorkLogHistoryState>(
        builder: (context, state) => switch (state) {
          WorkLogHistoryLoading() => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          WorkLogHistoryFailure(:final message) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  AmMainFab(
                    width: 180,
                    height: 48,
                    label: 'RIPROVA',
                    color: AmThemeColors.of(context).accent,
                    onPressed: () => context.read<WorkLogHistoryBloc>().add(
                      const WorkLogHistoryRefreshRequested(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          WorkLogHistoryLoaded(:final entries) =>
            entries.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Nessun lavoro registrato')),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    sliver: SliverList.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox.shrink(),
                      itemBuilder: (_, index) => WorkLogItemCard(
                        entry: entries[index],
                        onTap: () => onEntryPressed(entries[index]),
                      ),
                    ),
                  ),
        },
      );
}
