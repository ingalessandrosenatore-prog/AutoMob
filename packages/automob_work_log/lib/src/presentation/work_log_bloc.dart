import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_use_cases.dart';

sealed class WorkLogHistoryEvent {
  const WorkLogHistoryEvent();
}

class WorkLogHistoryOpened extends WorkLogHistoryEvent {
  const WorkLogHistoryOpened(this.vehicleId);
  final String vehicleId;
}

class WorkLogHistoryRefreshRequested extends WorkLogHistoryEvent {
  const WorkLogHistoryRefreshRequested();
}

class WorkLogHistoryLoadMoreRequested extends WorkLogHistoryEvent {
  const WorkLogHistoryLoadMoreRequested();
}

sealed class WorkLogHistoryState {
  const WorkLogHistoryState();
}

class WorkLogHistoryLoading extends WorkLogHistoryState {
  const WorkLogHistoryLoading();
}

class WorkLogHistoryLoaded extends WorkLogHistoryState {
  const WorkLogHistoryLoaded({
    required this.entries,
    required this.hasReachedMax,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.refreshError,
  });

  final List<WorkLogEntry> entries;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? refreshError;
}

class WorkLogHistoryFailure extends WorkLogHistoryState {
  const WorkLogHistoryFailure(this.message);
  final String message;
}

class WorkLogHistoryBloc
    extends Bloc<WorkLogHistoryEvent, WorkLogHistoryState> {
  WorkLogHistoryBloc({required this.getVehicleWorkHistory})
    : super(const WorkLogHistoryLoading()) {
    on<WorkLogHistoryOpened>(_onOpened);
    on<WorkLogHistoryRefreshRequested>(_onRefresh);
    on<WorkLogHistoryLoadMoreRequested>(_onLoadMore);
  }

  static const pageSize = 20;
  final GetVehicleWorkHistory getVehicleWorkHistory;
  String? _vehicleId;

  Future<void> _onOpened(
    WorkLogHistoryOpened event,
    Emitter<WorkLogHistoryState> emit,
  ) async {
    _vehicleId = event.vehicleId;
    emit(const WorkLogHistoryLoading());
    await _loadPage(emit, vehicleId: event.vehicleId, from: 0, replace: true);
  }

  Future<void> _onRefresh(
    WorkLogHistoryRefreshRequested event,
    Emitter<WorkLogHistoryState> emit,
  ) async {
    if (_vehicleId == null) {
      return;
    }
    final vehicleId = _vehicleId!;
    final current = state;
    if (current is WorkLogHistoryLoaded) {
      emit(
        WorkLogHistoryLoaded(
          entries: current.entries,
          hasReachedMax: current.hasReachedMax,
          isRefreshing: true,
        ),
      );
    }
    await _loadPage(
      emit,
      vehicleId: vehicleId,
      from: 0,
      replace: true,
      retained: current is WorkLogHistoryLoaded ? current : null,
    );
  }

  Future<void> _onLoadMore(
    WorkLogHistoryLoadMoreRequested event,
    Emitter<WorkLogHistoryState> emit,
  ) async {
    final current = state;
    if (_vehicleId == null ||
        current is! WorkLogHistoryLoaded ||
        current.hasReachedMax ||
        current.isLoadingMore) {
      return;
    }
    emit(
      WorkLogHistoryLoaded(
        entries: current.entries,
        hasReachedMax: false,
        isLoadingMore: true,
      ),
    );
    await _loadPage(
      emit,
      vehicleId: _vehicleId!,
      from: current.entries.length,
      replace: false,
      retained: current,
    );
  }

  Future<void> _loadPage(
    Emitter<WorkLogHistoryState> emit, {
    required String vehicleId,
    required int from,
    required bool replace,
    WorkLogHistoryLoaded? retained,
  }) async {
    final result = await getVehicleWorkHistory(
      vehicleId,
      from: from,
      to: from + pageSize - 1,
    );
    if (_vehicleId != vehicleId) return;
    result.fold(
      (message) {
        if (retained != null) {
          emit(
            WorkLogHistoryLoaded(
              entries: retained.entries,
              hasReachedMax: retained.hasReachedMax,
              refreshError: message,
            ),
          );
        } else {
          emit(WorkLogHistoryFailure(message));
        }
      },
      (entries) {
        final previous = state;
        final items = !replace && previous is WorkLogHistoryLoaded
            ? [...previous.entries, ...entries]
            : entries;
        emit(
          WorkLogHistoryLoaded(
            entries: items,
            hasReachedMax: entries.length < pageSize,
          ),
        );
      },
    );
  }
}
