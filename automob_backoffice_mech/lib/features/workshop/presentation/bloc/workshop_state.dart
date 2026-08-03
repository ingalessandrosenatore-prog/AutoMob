import 'package:equatable/equatable.dart';

import '../../domain/entities/workshop_catalog.dart';

sealed class WorkshopState extends Equatable {
  const WorkshopState();
}

final class WorkshopInitial extends WorkshopState {
  const WorkshopInitial();

  @override
  List<Object?> get props => const [];
}

final class WorkshopLoading extends WorkshopState {
  const WorkshopLoading();

  @override
  List<Object?> get props => const [];
}

final class WorkshopReady extends WorkshopState {
  const WorkshopReady({
    required this.mechanic,
    required this.allVehicles,
    required this.filteredVehicles,
    required this.query,
    required this.visibleCount,
  });

  static const pageSize = 20;

  final WorkshopMechanic mechanic;
  final List<WorkshopVehicle> allVehicles;
  final List<WorkshopVehicle> filteredVehicles;
  final String query;
  final int visibleCount;

  List<WorkshopVehicle> get visibleVehicles => filteredVehicles
      .take(visibleCount.clamp(0, filteredVehicles.length))
      .toList(growable: false);

  bool get hasMore => visibleCount < filteredVehicles.length;

  WorkshopReady copyWith({
    List<WorkshopVehicle>? filteredVehicles,
    String? query,
    int? visibleCount,
  }) => WorkshopReady(
    mechanic: mechanic,
    allVehicles: allVehicles,
    filteredVehicles: filteredVehicles ?? this.filteredVehicles,
    query: query ?? this.query,
    visibleCount: visibleCount ?? this.visibleCount,
  );

  @override
  List<Object?> get props => [
    mechanic,
    allVehicles,
    filteredVehicles,
    query,
    visibleCount,
  ];
}

final class WorkshopLoadFailure extends WorkshopState {
  const WorkshopLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
