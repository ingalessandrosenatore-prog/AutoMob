sealed class WorkshopEvent {
  const WorkshopEvent();
}

final class WorkshopStarted extends WorkshopEvent {
  const WorkshopStarted();
}

final class WorkshopRetryRequested extends WorkshopEvent {
  const WorkshopRetryRequested();
}

final class WorkshopSearchChanged extends WorkshopEvent {
  const WorkshopSearchChanged(this.query);

  final String query;
}

final class WorkshopVisibleWindowRequested extends WorkshopEvent {
  const WorkshopVisibleWindowRequested(this.expectedVisibleCount);

  final int expectedVisibleCount;
}
