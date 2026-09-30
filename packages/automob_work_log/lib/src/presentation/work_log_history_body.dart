import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_launch_context.dart';
import 'work_log_bloc.dart';
import 'work_log_history_filter.dart';
import 'work_log_item_card.dart';

/// Corpo riutilizzabile dello storico: la cornice (AppBar e router) resta
/// nell'app chiamante, ma caricamento, lista e stato vuoto sono condivisi.
class WorkLogHistoryBody extends StatefulWidget {
  const WorkLogHistoryBody({
    required this.context,
    required this.bloc,
    required this.onEntryPressed,
    super.key,
    this.header,
  });

  final WorkLogLaunchContext context;
  final WorkLogHistoryBloc bloc;
  final ValueChanged<WorkLogEntry> onEntryPressed;
  final Widget? header;

  @override
  State<WorkLogHistoryBody> createState() => _WorkLogHistoryBodyState();
}

class _WorkLogHistoryBodyState extends State<WorkLogHistoryBody> {
  @override
  void initState() {
    super.initState();
    // A route rebuild after returning from a child must not reset an already
    // loaded history to the full-screen loading state.
    if (widget.bloc.state is! WorkLogHistoryLoaded) {
      widget.bloc.add(WorkLogHistoryOpened(widget.context.vehicleId));
    }
  }

  @override
  void didUpdateWidget(covariant WorkLogHistoryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context.vehicleId != widget.context.vehicleId) {
      widget.bloc.add(WorkLogHistoryOpened(widget.context.vehicleId));
    }
  }

  Future<void> _refresh() async {
    widget.bloc.add(const WorkLogHistoryRefreshRequested());
    await widget.bloc.stream.firstWhere(
      (state) =>
          state is WorkLogHistoryLoaded || state is WorkLogHistoryFailure,
    );
  }

  @override
  Widget build(BuildContext buildContext) => BlocProvider.value(
    value: widget.bloc,
    child: Column(
      children: [
        ?widget.header,
        Expanded(
          child: BlocBuilder<WorkLogHistoryBloc, WorkLogHistoryState>(
            builder: (context, state) => switch (state) {
              WorkLogHistoryLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              WorkLogHistoryFailure(:final message) => _HistoryFailure(
                message: message,
                onRetry: () => widget.bloc.add(
                  WorkLogHistoryOpened(widget.context.vehicleId),
                ),
              ),
              WorkLogHistoryLoaded(:final entries, :final visibleEntries) =>
                entries.isEmpty
                    ? _EmptyHistory(onRefresh: _refresh)
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                          itemCount: visibleEntries.length + 2,
                          itemBuilder: (_, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: WorkLogHistoryFilter(
                                  selectedType: state.selectedType,
                                  onChanged: (type) => widget.bloc.add(
                                    WorkLogHistoryFilterSelected(type),
                                  ),
                                ),
                              );
                            }
                            if (index == visibleEntries.length + 1) {
                              if (visibleEntries.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 70),
                                  child: Center(
                                    child: Text(
                                      'Nessun lavoro per questo filtro',
                                    ),
                                  ),
                                );
                              }
                              return state.hasReachedMax
                                  ? const SizedBox.shrink()
                                  : TextButton(
                                      onPressed: state.isLoadingMore
                                          ? null
                                          : () => widget.bloc.add(
                                              const WorkLogHistoryLoadMoreRequested(),
                                            ),
                                      child: Text(
                                        state.isLoadingMore
                                            ? 'Caricamento…'
                                            : 'Carica altri lavori',
                                      ),
                                    );
                            }
                            final entry = visibleEntries[index - 1];
                            return WorkLogItemCard(
                              key: ValueKey('work-log-item-${entry.id}'),
                              entry: entry,
                              entranceIndex: index - 1,
                              onTap: () => widget.onEntryPressed(entry),
                            );
                          },
                        ),
                      ),
            },
          ),
        ),
      ],
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onRefresh});

  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 160),
        Center(child: Text('Nessun lavoro registrato')),
      ],
    ),
  );
}

class _HistoryFailure extends StatelessWidget {
  const _HistoryFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
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
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
