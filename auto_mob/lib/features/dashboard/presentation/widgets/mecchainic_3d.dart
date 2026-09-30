import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'mechanic_scene.dart';

class Mecchainic3d extends StatefulWidget {
  const Mecchainic3d({
    super.key,
    required this.assetPath,
    this.onTap,
    this.loader = MechanicScene.load,
  });

  final String assetPath;
  final VoidCallback? onTap;
  final Future<MechanicScene> Function(String) loader;

  @override
  State<Mecchainic3d> createState() => _Mecchainic3dState();
}

class _Mecchainic3dState extends State<Mecchainic3d> {
  late Future<MechanicScene> _loading;
  final _camera = PerspectiveCamera(
    position: vm.Vector3(0, 2.6, -9),
    target: vm.Vector3(0, 2.5, 0),
  );

  @override
  void initState() {
    super.initState();
    // Keep the Future: rebuilding the Home must not reload the GLB.
    _loading = widget.loader(widget.assetPath);
  }

  @override
  void didUpdateWidget(covariant Mecchainic3d oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _release(_loading);
      _loading = widget.loader(widget.assetPath);
    }
  }

  void _release(Future<MechanicScene> loading) {
    // If navigation happens during loading, release after the load finishes.
    unawaited(
      loading.then((value) => value.release()).catchError((Object error) {
        debugPrint('Mechanic3D resource release: $error');
      }),
    );
  }

  @override
  void dispose() {
    _release(_loading);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MechanicScene>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Impossibile caricare il personaggio 3D.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return GestureDetector(
        onTap: widget.onTap,
        child: SceneView(snapshot.data!.scene, camera: _camera),
      );
    },
  );
}
