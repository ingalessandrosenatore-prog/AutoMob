import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workshop_overview.dart';
import '../../domain/usecases/get_workshop_overview.dart';

class WorkshopOverviewCubit extends Cubit<WorkshopOverview> {
  WorkshopOverviewCubit(this.getOverview)
    : super(getOverview(WorkshopPeriod.day));

  final GetWorkshopOverview getOverview;

  void selectPeriod(WorkshopPeriod period) {
    if (period != state.period) emit(getOverview(period));
  }
}
