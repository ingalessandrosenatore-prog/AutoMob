import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../domain/work_log_entry.dart';
import 'work_log_bloc.dart';
import 'work_log_history_filter.dart';
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
          WorkLogHistoryLoaded(:final entries, :final visibleEntries) =>
            entries.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Nessun lavoro registrato')),
                  )
                : SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                          child: WorkLogHistoryFilter(
                            selectedType: state.selectedType,
                            onChanged: (type) => context
                                .read<WorkLogHistoryBloc>()
                                .add(WorkLogHistoryFilterSelected(type)),
                          ),
                        ),
                      ),
                      if (visibleEntries.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 70),
                            child: Center(
                              child: Text('Nessun lavoro per questo filtro'),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverList.separated(
                            itemCount: visibleEntries.length,
                            separatorBuilder: (_, _) => const SizedBox.shrink(),
                            itemBuilder: (_, index) => WorkLogItemCard(
                              key: ValueKey(
                                'work-log-item-${visibleEntries[index].id}',
                              ),
                              entry: visibleEntries[index],
                              entranceIndex: index,
                              onTap: () =>
                                  onEntryPressed(visibleEntries[index]),
                            ),
                          ),
                        ),
                    ],
                  ),
        },
      );
}
