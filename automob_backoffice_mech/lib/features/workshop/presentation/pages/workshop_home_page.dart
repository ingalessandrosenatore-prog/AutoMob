import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../../../../core/widgets/mechanic_glass_icon_button.dart';
import '../../../../core/widgets/mechanic_shapes.dart';
import '../../../../core/widgets/mechanic_vehicle_card.dart';
import '../../domain/entities/workshop_catalog.dart';
import '../bloc/workshop_bloc.dart';
import '../bloc/workshop_event.dart';
import '../bloc/workshop_state.dart';

class WorkshopHomePage extends StatelessWidget {
  const WorkshopHomePage({super.key, this.onSettingsPressed});

  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) =>
      BlocListener<WorkshopBloc, WorkshopState>(
        listenWhen: (previous, current) => current is WorkshopLoadFailure,
        listener: (context, state) {
          if (state is WorkshopLoadFailure) _showLoadFailure(context, state);
        },
        child: BlocBuilder<WorkshopBloc, WorkshopState>(
          builder: (context, state) => switch (state) {
            WorkshopReady ready => _WorkshopHomeView(
              mechanicName: ready.mechanic.displayName,
              totalVehicles: ready.allVehicles.length,
              vehicles: ready.visibleVehicles,
              hasLinkedVehicles: ready.allVehicles.isNotEmpty,
              hasSearchResults: ready.filteredVehicles.isNotEmpty,
              visibleCount: ready.visibleCount,
              hasMore: ready.hasMore,
              query: ready.query,
              onSettingsPressed: onSettingsPressed,
            ),
            WorkshopLoading() => _WorkshopHomeView(
              mechanicName: 'Meccanico',
              isLoading: true,
              onSettingsPressed: onSettingsPressed,
            ),
            WorkshopInitial() => _WorkshopHomeView(
              mechanicName: 'Meccanico',
              isLoading: true,
              onSettingsPressed: onSettingsPressed,
            ),
            WorkshopLoadFailure() => _WorkshopHomeView(
              mechanicName: 'Meccanico',
              hasLoadFailure: true,
              onSettingsPressed: onSettingsPressed,
            ),
          },
        ),
      );

  void _showLoadFailure(BuildContext context, WorkshopLoadFailure state) {
    final colors = AmThemeColors.of(context);
    showAmStatusDialog<void>(
      context,
      title: 'Impossibile caricare i veicoli',
      message: state.message,
      iconColor: colors.danger,
      actions: [
        AmDialogAction(
          label: 'Chiudi',
          color: colors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AmDialogAction(
          label: 'Riprova',
          color: colors.accent,
          filled: true,
          onPressed: () {
            Navigator.of(context).pop();
            context.read<WorkshopBloc>().add(const WorkshopRetryRequested());
          },
        ),
      ],
    );
  }
}

class _WorkshopHomeView extends StatelessWidget {
  const _WorkshopHomeView({
    required this.mechanicName,
    this.totalVehicles = 0,
    this.vehicles = const [],
    this.hasLinkedVehicles = false,
    this.hasSearchResults = false,
    this.visibleCount = WorkshopReady.pageSize,
    this.hasMore = false,
    this.query = '',
    this.isLoading = false,
    this.hasLoadFailure = false,
    this.onSettingsPressed,
  });

  final String mechanicName;
  final int totalVehicles;
  final List<WorkshopVehicle> vehicles;
  final bool hasLinkedVehicles;
  final bool hasSearchResults;
  final int visibleCount;
  final bool hasMore;
  final String query;
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Stack(
            children: [
              Positioned.fill(
                child: SoftEdgeBlur(
                  edges: [
                    EdgeBlur(
                      type: EdgeType.topEdge,
                      size: 72,
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
                      size: 92,
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
                  child: CustomScrollView(
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
                          child: _ClientListHeading(total: totalVehicles),
                        ),
                      ),
                      ..._contentSlivers(context),
                    ],
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('workshop_app_bar'),
                top: topInset,
                left: 24,
                right: 20,
                height: appBarHeight,
                child: _WorkshopAppBar(
                  mechanicName: mechanicName,
                  onSettingsPressed: onSettingsPressed,
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('workshop_search_row'),
                left: 18,
                right: 18,
                bottom: keyboardInset + 14,
                duration: mediaQuery.disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: _VehicleSearchControls(
                  enabled: !isLoading && !hasLoadFailure,
                  onSearchChanged: (value) => context.read<WorkshopBloc>().add(
                    WorkshopSearchChanged(value),
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
          child: _LoadFailurePlaceholder(
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
          sliver: SliverToBoxAdapter(child: _EmptyWorkshopState()),
        ),
      ];
    }
    if (!hasSearchResults) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 140),
          sliver: SliverToBoxAdapter(child: _NoSearchResults(query: query)),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 112),
        sliver: SliverList.separated(
          itemCount: vehicles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
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
            );
          },
        ),
      ),
    ];
  }
}

class _ClientListHeading extends StatelessWidget {
  const _ClientListHeading({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'I tuoi clienti',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize:14,
              fontWeight: FontWeight.w600,

            ),
          ),
        ),
        Text(
          '$total totali',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WorkshopAppBar extends StatelessWidget {
  const _WorkshopAppBar({required this.mechanicName, this.onSettingsPressed});

  final String mechanicName;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _MechanicGreeting(name: mechanicName)),
      const SizedBox(width: 16),
      MechanicGlassIconButton(
        icon: Icons.settings_rounded,
        tooltip: 'Impostazioni',
        onPressed: onSettingsPressed,
        dimension: 48,
      ),
    ],
  );
}

class _MechanicGreeting extends StatelessWidget {
  const _MechanicGreeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colors.surfaceRaised,
          child: Icon(Icons.handyman_rounded, color: colors.accent, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buon lavoro,',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w200,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,

                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyWorkshopState extends StatelessWidget {
  const _EmptyWorkshopState();

  @override
  Widget build(BuildContext context) => const _MessagePlaceholder(
    icon: Icons.directions_car_filled_rounded,
    title: 'Non hai veicoli collegati alla tua officina',
    message: 'Invita i clienti inserendo il tuo codice officina.',
  );
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => _MessagePlaceholder(
    icon: Icons.search_off_rounded,
    title: 'Nessun veicolo trovato',
    message: 'Nessun risultato per “$query”. Prova con marca, modello o targa.',
  );
}

class _MessagePlaceholder extends StatelessWidget {
  const _MessagePlaceholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.18),
                    blurRadius: 36,
                  ),
                ],
              ),
              child: Icon(icon, size: 54, color: colors.accent),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailurePlaceholder extends StatelessWidget {
  const _LoadFailurePlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(onPressed: onRetry, child: const Text('Riprova')),
  );
}

class _VehicleSearchControls extends StatelessWidget {
  const _VehicleSearchControls({
    required this.enabled,
    required this.onSearchChanged,
  });

  final bool enabled;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return RepaintBoundary(
      child: OCLiquidGlassGroup(
        settings: const OCLiquidGlassSettings(
          refractStrength: -0.12,
          blurRadiusPx: 15,
          specStrength: 0.18,
          specWidth: 0.8,
          specAngle: 145,
          specPower: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: mechanicSmoothShape(radius: 28),
                  ),
                  child: OCLiquidGlass(
                    borderRadius: 28,
                    color: colors.surfaceRaised.withValues(alpha: 0.2),
                    child: TextField(
                      enabled: enabled,
                      onChanged: onSearchChanged,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Cerca targa, marca o modello...',
                        hintStyle: TextStyle(color: colors.textSecondary),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colors.textSecondary,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            MechanicGlassIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Filtri non ancora disponibili',
              onPressed: null,
              foregroundColor: colors.accent.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            const MechanicGlassIconButton(
              icon: Icons.mic_none_rounded,
              tooltip: 'Ricerca vocale non ancora disponibile',
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}
