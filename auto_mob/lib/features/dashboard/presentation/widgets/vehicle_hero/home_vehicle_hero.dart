import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../vehicle/domain/entities/maintenance_kpi.dart';
import 'vehicle_hero_callouts.dart';
import 'vehicle_hero_scene.dart';
import 'vehicle_hero_stage.dart';

class HomeVehicleHero extends StatefulWidget {
  const HomeVehicleHero({
    super.key,
    required this.kpis,
    required this.onKpiTap,
  });

  final List<MaintenanceKpi> kpis;
  final Future<void> Function(MaintenanceKpi) onKpiTap;

  @override
  State<HomeVehicleHero> createState() => _HomeVehicleHeroState();
}

class _HomeVehicleHeroState extends State<HomeVehicleHero> {
  late final Future<VehicleHeroScene> _scene = VehicleHeroScene.load();

  @override
  void initState() {
    super.initState();
    unawaited(_scene.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
  }

  @override
  void dispose() {
    unawaited(_scene.then((scene) => scene.dispose(), onError: (Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callouts = VehicleHeroCallout.forKpis(widget.kpis);
    if (callouts.isEmpty) return const SizedBox.shrink();
    return FutureBuilder(
      future: _scene,
      builder: (context, snapshot) => VehicleHeroStage(
        scene: snapshot.data,
        loading: snapshot.connectionState != ConnectionState.done,
        callouts: callouts,
        onKpiTap: widget.onKpiTap,
      ),
    );
  }
}
