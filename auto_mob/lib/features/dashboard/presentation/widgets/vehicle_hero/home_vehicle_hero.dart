import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import '../../../../vehicle/domain/entities/maintenance_kpi.dart';
import 'vehicle_hero_callouts.dart';
import 'vehicle_hero_scene.dart';
import 'vehicle_hero_scroll_trigger.dart';

class HomeVehicleHero extends StatefulWidget {
  const HomeVehicleHero({
    super.key,
    required this.kpis,
    required this.onKpiTap,
    required this.topObstruction,
  });

  final List<MaintenanceKpi> kpis;
  final ValueChanged<MaintenanceKpi> onKpiTap;
  final double topObstruction;

  @override
  State<HomeVehicleHero> createState() => _HomeVehicleHeroState();
}

class _HomeVehicleHeroState extends State<HomeVehicleHero> {
  late final Future<VehicleHeroScene> _scene = VehicleHeroScene.load();
  final _revealed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // Start asset IO and GPU initialization while the dashboard fetches data.
    unawaited(_scene.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
  }

  @override
  void dispose() {
    unawaited(_scene.then((scene) => scene.dispose(), onError: (Object _) {}));
    _revealed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * .41).clamp(
      286.0,
      386.0,
    );
    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: ClipRect(
          child: FutureBuilder(
            future: _scene,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('AutoMob vehicle Scene: ${snapshot.error}');
                return const Center(child: Text('Vista 3D non disponibile'));
              }
              final scene = snapshot.data;
              return VehicleHeroScrollTrigger(
                ready: scene != null,
                topObstruction: widget.topObstruction,
                onReveal: () => _revealed.value = true,
                child: scene == null
                    ? const SizedBox.expand()
                    : ValueListenableBuilder(
                        valueListenable: _revealed,
                        builder: (context, revealed, _) => _VehicleHeroPlayback(
                          scene: scene,
                          kpis: widget.kpis,
                          onKpiTap: widget.onKpiTap,
                          revealed: revealed,
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VehicleHeroPlayback extends StatefulWidget {
  const _VehicleHeroPlayback({
    required this.scene,
    required this.kpis,
    required this.onKpiTap,
    required this.revealed,
  });

  final VehicleHeroScene scene;
  final List<MaintenanceKpi> kpis;
  final ValueChanged<MaintenanceKpi> onKpiTap;
  final bool revealed;

  @override
  State<_VehicleHeroPlayback> createState() => _VehicleHeroPlaybackState();
}

class _VehicleHeroPlaybackState extends State<_VehicleHeroPlayback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  final _driving = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.scene.drive(0);
    _intro = AnimationController(
      vsync: this,
      duration: VehicleHeroCallouts.duration,
    )..addListener(_moveVehicle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startIfRevealed();
  }

  @override
  void didUpdateWidget(_VehicleHeroPlayback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed && !oldWidget.revealed) _startIfRevealed();
  }

  void _startIfRevealed() {
    if (!widget.revealed || _intro.isAnimating || _intro.isCompleted) return;
    _driving.value = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  void _moveVehicle() {
    if (!_driving.value) return;
    final time = (_intro.value / VehicleHeroCallouts.arrival).clamp(0.0, 1.0);
    widget.scene.drive(Curves.easeOutCubic.transform(time));
    if (time == 1) _driving.value = false;
  }

  @override
  void dispose() {
    _intro.dispose();
    _driving.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ValueListenableBuilder(
            valueListenable: _driving,
            builder: (context, driving, _) => AnimatedBuilder(
              animation: driving ? _intro : kAlwaysDismissedAnimation,
              builder: (context, _) => RepaintBoundary(
                child: SceneView(
                  widget.scene.scene,
                  camera: widget.scene.camera,
                  autoTick: false,
                  pixelRatio: MediaQuery.devicePixelRatioOf(
                    context,
                  ).clamp(1.0, 1.65),
                ),
              ),
            ),
          ),
        ),
        VehicleHeroCallouts(
          scene: widget.scene,
          animation: _intro,
          kpis: widget.kpis,
          onKpiTap: widget.onKpiTap,
        ),
      ],
    );
  }
}
