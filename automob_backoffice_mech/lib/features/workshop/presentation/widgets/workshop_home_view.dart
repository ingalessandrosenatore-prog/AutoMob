import 'dart:math' as math;

import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../../../../core/router/mechanic_shell_metrics.dart';
import '../../../../core/widgets/mechanic_vehicle_card.dart';
import '../../domain/entities/workshop_catalog.dart';
import '../bloc/voice_search_bloc.dart';
import '../bloc/voice_search_state.dart';
import '../bloc/workshop_bloc.dart';
import '../bloc/workshop_event.dart';
import '../bloc/workshop_state.dart';
import '../bloc/workshop_vehicle_filter.dart';
import 'workshop_header.dart';
import 'workshop_home_placeholders.dart';
import 'workshop_search_controls.dart';
import 'workshop_voice_button.dart';

/// Composizione visuale della Home dell'officina.
///
/// Riceve solo lo snapshot già preparato dalla pagina e inoltra le azioni
/// della UI al [WorkshopBloc]. Non possiede accesso a use case o repository:
/// la pagina resta il punto di composizione dei BLoC e dei loro effetti.
class WorkshopHomeView extends StatelessWidget {
  const WorkshopHomeView({
    super.key,
    required this.mechanicName,
    required this.searchController,
    required this.onVoicePressed,
    this.totalVehicles = 0,
    this.vehicles = const [],
    this.hasLinkedVehicles = false,
    this.hasSearchResults = false,
    this.visibleCount = WorkshopReady.pageSize,
    this.hasMore = false,
    this.query = '',
    this.filter = WorkshopVehicleFilter.all,
    this.isLoading = false,
    this.hasLoadFailure = false,
    this.onSettingsPressed,
  });

  final String mechanicName;
  final TextEditingController searchController;
  final ValueChanged<VoiceSearchState> onVoicePressed;
  final int totalVehicles;
  final List<WorkshopVehicle> vehicles;
  final bool hasLinkedVehicles;
  final bool hasSearchResults;
  final int visibleCount;
  final bool hasMore;
  final String query;
  final WorkshopVehicleFilter filter;
  final bool isLoading;
  final bool hasLoadFailure;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    const appBarHeight = 80.0;
    final appBarExtent = topInset + appBarHeight;

    // AppShell owns the bottom navigation and publishes its resolved inset.
    // Using it here keeps the microphone and the search row on the same
    // physical coordinate even when Scaffold changes MediaQuery padding.
    final shellControlsBottom = MechanicShellGeometry.of(
      context,
    ).controlsBottom;
    final restingSearchBottom =
        shellControlsBottom +
        MechanicShellMetrics.navigationHeight +
        MechanicShellMetrics.searchNavigationGap;
    final searchBottom = keyboardInset > 0
        ? math.max(restingSearchBottom, keyboardInset + 12)
        : restingSearchBottom;
    final bottomBlurExtent = 92 + searchBottom - restingSearchBottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  key: const ValueKey('workshop_edge_blur'),
                  tween: Tween(end: bottomBlurExtent),
                  duration: mediaQuery.disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedBottomExtent, child) =>
                      /* SoftEdgeBlur(
                        edges: [
                          EdgeBlur(
                            type: EdgeType.topEdge,
                            size: 180,
                            tintColor: colors.background,
                            sigma: 10,
                            controlPoints: [
                              ControlPoint(
                                position: 0.5,
                                type: ControlPointType.visible,
                              ),
                              ControlPoint(
                                position: 1,
                                type: ControlPointType.transparent,
                              ),
                            ],
                          ),
                          EdgeBlur(
                            type: EdgeType.bottomEdge,
                            size: animatedBottomExtent,
                            tintColor: colors.background,
                            sigma: 10,
                            controlPoints: [
                              ControlPoint(
                                position: 0.5,
                                type: ControlPointType.visible,
                              ),
                              ControlPoint(
                                position: 1,
                                type: ControlPointType.transparent,
                              ),
                            ],
                          ),
                        ],
                        child: */
                      CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(height: appBarExtent + 18),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                            sliver: SliverToBoxAdapter(
                              child: WorkshopClientListHeading(
                                total: totalVehicles,
                              ),
                            ),
                          ),
                          ..._contentSlivers(context),
                        ],
                      ),
                  /* ), */
                ),
              ),
              Positioned(
                key: const ValueKey('workshop_app_bar'),
                top: topInset,
                left: 24,
                right: 20,
                height: appBarHeight,
                child: WorkshopAppBar(
                  mechanicName: mechanicName,
                  onSettingsPressed: onSettingsPressed,
                ),
              ),
              _AnimatedWorkshopSearchPosition(
                positionedKey: const ValueKey('workshop_search_row'),
                left: MechanicShellMetrics.horizontalMargin,
                right: MechanicShellMetrics.horizontalMargin,
                bottom: searchBottom,
                duration: mediaQuery.disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 50),
                childBuilder: (repaint) => WorkshopSearchControls(
                  enabled: !isLoading && !hasLoadFailure,
                  controller: searchController,
                  filter: filter,
                  repaint: repaint,
                  onSearchChanged: (value) => context.read<WorkshopBloc>().add(
                    WorkshopSearchChanged(value),
                  ),
                  onFilterChanged: (filter) => context.read<WorkshopBloc>().add(
                    WorkshopVehicleFilterChanged(filter),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('workshop_voice_button'),
                right: MechanicShellMetrics.horizontalMargin,
                bottom: shellControlsBottom,
                width: MechanicShellMetrics.microphoneSize,
                height: MechanicShellMetrics.microphoneSize,
                child:
                    BlocSelector<
                      VoiceSearchBloc,
                      VoiceSearchState,
                      VoiceSearchState
                    >(
                      // Audio amplitude changes rebuild only this selector and
                      // the microphone, not the vehicle list or SearchBar.
                      selector: (state) => state,
                      builder: (context, voiceState) => WorkshopVoiceButton(
                        state: voiceState,
                        onPressed: () => onVoicePressed(voiceState),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(BuildContext context) {
    // These states are intentionally mutually exclusive and ordered from
    // transport state to data state, so an empty result never masks an error.
    if (isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (hasLoadFailure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: WorkshopLoadFailurePlaceholder(
            onRetry: () => context.read<WorkshopBloc>().add(
              const WorkshopRetryRequested(),
            ),
          ),
        ),
      ];
    }
    if (!hasLinkedVehicles) {
      return const [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(24, 40, 24, 140),
          sliver: SliverToBoxAdapter(child: WorkshopEmptyState()),
        ),
      ];
    }
    if (!hasSearchResults) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
          sliver: SliverToBoxAdapter(
            child: WorkshopNoSearchResults(query: query),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 160),
        sliver: SliverList.separated(
          itemCount: vehicles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (hasMore && index == math.max(0, vehicles.length - 5)) {
              context.read<WorkshopBloc>().add(
                WorkshopVisibleWindowRequested(visibleCount),
              );
            }
            return MechanicVehicleCard(
              vehicle: MechanicVehicleCardData(
                id: vehicles[index].id,
                name: vehicles[index].displayName,
                plate: vehicles[index].plate,
                year: vehicles[index].year,
                kilometers: vehicles[index].kmCurrent,
                status: vehicles[index].requiresMaintenance
                    ? MechanicVehicleStatus.attention
                    : MechanicVehicleStatus.connected,
              ),
              onPressed: () => context.pushNamed(
                'vehicleConfiguration',
                pathParameters: {'vehicleId': vehicles[index].id},
                extra: MechanicWorkLogLaunch(
                  vehicle: WorkLogVehicle(
                    id: vehicles[index].id,
                    name: vehicles[index].displayName,
                    plate: vehicles[index].plate,
                    currentKm: vehicles[index].kmCurrent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _AnimatedWorkshopSearchPosition extends StatefulWidget {
  const _AnimatedWorkshopSearchPosition({
    required this.positionedKey,
    required this.left,
    required this.right,
    required this.bottom,
    required this.duration,
    required this.childBuilder,
  });

  final Key positionedKey;
  final double left;
  final double right;
  final double bottom;
  final Duration duration;
  final Widget Function(Listenable repaint) childBuilder;

  @override
  State<_AnimatedWorkshopSearchPosition> createState() =>
      _AnimatedWorkshopSearchPositionState();
}

class _AnimatedWorkshopSearchPositionState
    extends State<_AnimatedWorkshopSearchPosition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _bottomAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _bottomAnimation = AlwaysStoppedAnimation(widget.bottom);
  }

  @override
  void didUpdateWidget(covariant _AnimatedWorkshopSearchPosition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bottom != widget.bottom ||
        oldWidget.duration != widget.duration) {
      _animateTo(widget.bottom, widget.duration);
    }
  }

  void _animateTo(double target, Duration duration) {
    final begin = _bottomAnimation.value;
    _controller
      ..stop()
      ..duration = duration;
    _bottomAnimation = Tween<double>(
      begin: begin,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The child is built once per widget update; animation ticks only move
    // the Positioned wrapper and repaint the glass render layer.
    final child = widget.childBuilder(_controller);
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, child) => Positioned(
        key: widget.positionedKey,
        left: widget.left,
        right: widget.right,
        bottom: _bottomAnimation.value,
        child: child!,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
