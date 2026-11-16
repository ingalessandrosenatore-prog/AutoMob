import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import 'mechanic_shapes.dart';
import 'mechanic_vehicle_card_work_models.dart';
import 'mechanic_vehicle_card_works_drawer.dart';
import 'mechanic_vehicle_work_badge.dart';

export 'mechanic_vehicle_card_work_models.dart';

enum MechanicVehicleStatus { connected, pending, attention, service }

class MechanicVehicleCardData {
  const MechanicVehicleCardData({
    required this.id,
    required this.name,
    required this.plate,
    required this.year,
    required this.kilometers,
    this.status = MechanicVehicleStatus.connected,
    this.warningLights = const [],
    this.mandatoryWorks = const [],
    this.userProblems = const [],
    this.estimatedRevenueEuro = 150,
  });

  final List<AmWarningLightData> warningLights;
  final List<MechanicMandatoryWorkItemData> mandatoryWorks;
  final List<MechanicUserProblemItemData> userProblems;
  final int estimatedRevenueEuro;
  final String id;
  final String name;
  final String plate;
  final int year;
  final int kilometers;
  final MechanicVehicleStatus status;

  int get totalWorksCount => mandatoryWorks.length + userProblems.length;

  bool get requiresWork =>
      status != MechanicVehicleStatus.connected ||
      totalWorksCount > 0 ||
      warningLights.isNotEmpty;

  String get worksCountLabel {
    final total = totalWorksCount;
    if (total == 1) return '1 lavoro da fare';
    if (total > 1) return '$total lavori da fare';
    return requiresWork ? 'Lavori da fare' : '0 lavori da fare';
  }
}

class MechanicVehicleCard extends StatefulWidget {
  const MechanicVehicleCard({required this.vehicle, super.key, this.onPressed});

  final MechanicVehicleCardData vehicle;
  final VoidCallback? onPressed;

  @override
  State<MechanicVehicleCard> createState() => _MechanicVehicleCardState();
}

class _MechanicVehicleCardState extends State<MechanicVehicleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final Animation<double> _expandAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<double> _chevronTurns = Tween<double>(
    begin: 0,
    end: 0.5,
  ).animate(_expandAnimation);

  void _toggleExpanded() {
    if (_controller.isCompleted ||
        _controller.status == AnimationStatus.forward) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MechanicUserProblemItemData> _resolvedUserProblems() {
    if (widget.vehicle.userProblems.isNotEmpty) {
      return widget.vehicle.userProblems;
    }
    if (widget.vehicle.warningLights.isNotEmpty) {
      return [
        MechanicUserProblemItemData(
          id: 'lights-${widget.vehicle.id}',
          description: '',
          warningLights: widget.vehicle.warningLights,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final upperCardShape = mechanicSmoothShape(radius: 10);
    const lowerSheetShape = SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius.only(
        bottomLeft: SmoothRadius(
          cornerRadius: 10,
          cornerSmoothing: mechanicCornerSmoothing,
        ),
        bottomRight: SmoothRadius(
          cornerRadius: 10,
          cornerSmoothing: mechanicCornerSmoothing,
        ),
      ),
    );
    final requiresWork = widget.vehicle.requiresWork;
    final statusColor = requiresWork ? colors.accent : colors.info;
    final userProblems = _resolvedUserProblems();

    // VerticalDirection.up disegna prima il foglio inferiore (dietro) e poi
    // la card principale sopra, così l'ombra della card principale cade sul
    // foglio sottostante proprio come nel design di riferimento.
    return Semantics(
      button: widget.onPressed != null,
      label: '${widget.vehicle.name}, targa ${widget.vehicle.plate}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        verticalDirection: VerticalDirection.up,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 38, right: 14),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.surfaceRaised.withValues(alpha: 0.92),
                shape: lowerSheetShape,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _controller.reverse,
                        child: TooltipVisibility(
                          visible: false,
                          child: MechanicVehicleCardWorksDrawer(
                            mandatoryWorks: widget.vehicle.mandatoryWorks,
                            userProblems: userProblems,
                            onOpenVehicle: widget.onPressed,
                          ),
                        ),
                      ),
                    ),
                    builder: (context, child) => ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _expandAnimation.value,
                        child: Opacity(
                          opacity: _expandAnimation.value,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        key: const Key('mechanic-vehicle-card-toggle'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleExpanded,
                        child: SizedBox(
                          height: 34,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.vehicle.worksCountLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: colors.textSecondary.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                RotationTransition(
                                  turns: _chevronTurns,
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: colors.textSecondary.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: DecoratedBox(
                  key: const Key('mechanic-vehicle-card-corner-border'),
                  decoration: ShapeDecoration(
                    gradient: colors.cardBorderGradient,
                    shape: upperCardShape,
                    shadows: colors.cardShadows,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.5),
                    child: Material(
                      color: colors.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: upperCardShape,
                      child: InkWell(
                        customBorder: upperCardShape,
                        onTap: _toggleExpanded,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: requiresWork ? 0.72 : 1.0,
                              child: SizedBox(
                                height: 3,
                                child: ColoredBox(color: statusColor),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                36,
                                18,
                                20,
                                16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        DecoratedBox(
                                          key: const Key(
                                            'mechanic-vehicle-plate',
                                          ),
                                          decoration: ShapeDecoration(
                                            color: colors.surfaceRaised,
                                            shape: mechanicSmoothShape(
                                              radius: 8,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                widget.vehicle.plate
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: colors.textPrimary,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          widget.vehicle.name.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${widget.vehicle.estimatedRevenueEuro}€',
                                    key: const Key(
                                      'mechanic-vehicle-estimated-revenue',
                                    ),
                                    style: TextStyle(
                                      color: requiresWork
                                          ? colors.accent
                                          : colors.textSecondary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                child: MechanicVehicleWorkBadge(requiresWork: requiresWork),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
