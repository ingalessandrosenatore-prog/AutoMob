import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workshop_overview.dart';
import '../../domain/usecases/get_workshop_overview.dart';
import 'workshop_overview_state.dart';

class WorkshopOverviewCubit extends Cubit<WorkshopOverviewState> {
  WorkshopOverviewCubit(this.getOverview, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const WorkshopOverviewLoading());

  final GetWorkshopOverview getOverview;
  final DateTime Function() _now;
  Future<void>? _pending;

  Future<void> load() =>
      _pending ??= _load().whenComplete(() => _pending = null);

  Future<void> refresh() => load();

  Future<void> _load() async {
    emit(const WorkshopOverviewLoading());
    try {
      final catalog = await getOverview(_now());
      if (!isClosed) {
        emit(WorkshopOverviewReady(catalog, period: WorkshopPeriod.day));
      }
    } on Object {
      if (!isClosed) emit(const WorkshopOverviewFailure());
    }
  }

  void selectPeriod(WorkshopPeriod period) {
    final current = state;
    if (current is WorkshopOverviewReady && period != current.period) {
      emit(WorkshopOverviewReady(current.catalog, period: period));
    }
  }
}
