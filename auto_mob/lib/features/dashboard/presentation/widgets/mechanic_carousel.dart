import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';

import 'mechanic_3d_configuration.dart';
import 'mechanic_carousel_layout.dart';
import 'mechanic_carousel_label.dart';
import 'mechanic_carousel_scene.dart';
import 'mechanic_carousel_edges.dart';
import 'mechanic_model_cache.dart';

/// @brief Carosello nativo con una sola SceneView e quattro posizioni visive.
/// @details Lo slot 1 è in primo piano. Lo swipe interpola posizione, scala e
/// rotazione; al rilascio raggiunge lo slot vicino e avvia il solo selezionato.
/// L'indice 0 è sempre il +; gli indici 1..N sono le officine.
/// @param configurations Aspetti già scelti, stabili per la sessione.
/// @param selectedIndex Selezione conservata dal BLoC per il veicolo corrente.
class MechanicCarousel extends StatefulWidget {
  const MechanicCarousel({
    super.key,
    required this.configurations,
    this.assetPath = 'lib/assets/mascot/automob_mascot.glb',
    this.onSelected,
    this.onAdd,
    this.onOpen,
    this.selectedIndex = 1,
    this.loader,
    this.isScrolling = false,
  });

  final List<Mechanic3dConfiguration> configurations;
  final String assetPath;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onOpen;
  final int selectedIndex;
  final bool isScrolling;
  final Future<MechanicCarouselScene> Function(
    String,
    List<Mechanic3dConfiguration>,
  )?
  loader;

  @override
  State<MechanicCarousel> createState() => _MechanicCarouselState();
}

class _MechanicCarouselState extends State<MechanicCarousel>
    with TickerProviderStateMixin {
  static const _sceneHeight = 272.0;
  static const _visibleHeight = 224.0;

  late final AnimationController _position;
  late final AnimationController _plusPulse;
  late MechanicModelCache _models;
  Future<MechanicCarouselScene>? _loading;
  MechanicCarouselScene? _scene;
  double _aspect = 1;
  double _dragStart = 0;
  double _dragPixels = 0;
  int _generation = 0;
  int _selected = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _models = MechanicModelCache(widget.assetPath);
    _selected = widget.selectedIndex.clamp(0, widget.configurations.length);
    _position = AnimationController.unbounded(
      vsync: this,
      value: _selected.toDouble(),
    )..addListener(_arrange);
    _plusPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlusPulse();
  }

  void _syncPlusPulse() {
    if (!widget.isScrolling &&
        _selected == 0 &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_plusPulse.isAnimating) _plusPulse.repeat(reverse: true);
    } else {
      _plusPulse.stop();
      _plusPulse.value = 0;
    }
  }

  void _load() {
    final generation = ++_generation;
    // Nessuna officina: il + resta utilizzabile senza caricare asset o GPU.
    if (widget.configurations.isEmpty || widget.isScrolling) {
      _loading = null;
      return;
    }
    final loading =
        widget.loader?.call(widget.assetPath, widget.configurations) ??
        MechanicCarouselScene.load(
          widget.assetPath,
          widget.configurations,
          models: _models,
        );
    _loading = loading;
    unawaited(
      loading.then(
        (scene) {
          if (!mounted || generation != _generation) return;
          _scene = scene;
          _arrange();
          _activate();
        },
        onError: (Object error, StackTrace stack) {
          // FutureBuilder displays the same load error in place of a blank scene.
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MechanicCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _disposeModels();
      _models = MechanicModelCache(widget.assetPath);
    }
    if (oldWidget.assetPath != widget.assetPath ||
        !listEquals(oldWidget.configurations, widget.configurations)) {
      _release(_loading);
      _scene = null;
      _position.stop();
      _dragging = false;
      _selected = widget.selectedIndex.clamp(0, widget.configurations.length);
      _position.value = _selected.toDouble();
      _syncPlusPulse();
      _load();
    } else if (oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex != _selected) {
      _position.stop();
      _dragging = false;
      _scene?.select(null);
      _selected = widget.selectedIndex.clamp(0, widget.configurations.length);
      _position.value = _selected.toDouble();
      _syncPlusPulse();
      _activate();
    }
    if (oldWidget.isScrolling != widget.isScrolling) {
      _syncPlusPulse();
      if (!widget.isScrolling) {
        if (_loading == null && widget.configurations.isNotEmpty) _load();
        _activate();
      }
    }
  }

  void _arrange() => _scene?.arrange(_position.value, _aspect);

  void _activate() {
    if (widget.isScrolling || _dragging || _position.isAnimating) return;
    _scene?.select(
      MediaQuery.disableAnimationsOf(context) || _selected == 0
          ? null
          : _selected - 1,
    );
  }

  /// @brief Completa lo swipe senza scatti e avvia la clip soltanto all'arrivo.
  Future<void> _settle(int index) async {
    final target = index.clamp(0, widget.configurations.length);
    _scene?.select(null);
    try {
      await _position
          .animateTo(
            target.toDouble(),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
          )
          .orCancel;
      if (!mounted) return;
      final changed = target != _selected;
      _selected = target;
      _position.value = target.toDouble();
      _syncPlusPulse();
      _activate();
      if (changed) widget.onSelected?.call(target);
    } on TickerCanceled {
      // A new swipe takes over the current transition; it is not a load error.
    }
  }

  void _release(Future<MechanicCarouselScene>? loading) {
    if (loading == null) return;
    unawaited(
      loading.then((scene) => scene.release()).catchError((Object error) {
        debugPrint('Rilascio carosello 3D: $error');
      }),
    );
  }

  @override
  void dispose() {
    _plusPulse.dispose();
    _position.dispose();
    _release(_loading);
    _disposeModels();
    super.dispose();
  }

  void _disposeModels() {
    unawaited(
      _models.dispose().catchError((Object error) {
        debugPrint('Rilascio modello 3D: $error');
      }),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _visibleHeight,
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: _sceneHeight,
        maxHeight: _sceneHeight,
        // La scena conserva il viewport originale per non cambiare dimensione
        // e prospettiva dei modelli; viene ritagliata solo la fascia vuota sotto.
        child: MechanicCarouselEdges(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _aspect = constraints.maxWidth / constraints.maxHeight;
              _arrange();
              return GestureDetector(
                key: const Key('mechanic_carousel_swipe'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _open(_selected),
                onHorizontalDragStart: (_) {
                  _dragging = true;
                  _plusPulse.stop();
                  _plusPulse.value = 0;
                  _position.stop();
                  _scene?.select(null);
                  _dragStart = _position.value;
                  _dragPixels = 0;
                },
                onHorizontalDragUpdate: (details) {
                  _dragPixels += details.primaryDelta ?? 0;
                  _position.value =
                      (_dragStart - _dragPixels / (constraints.maxWidth * .42))
                          .clamp(0, widget.configurations.length)
                          .toDouble();
                },
                onHorizontalDragEnd: (_) {
                  _dragging = false;
                  _settle(_position.value.round());
                },
                onHorizontalDragCancel: () {
                  _dragging = false;
                  _settle(_selected);
                },
                child: Stack(
                  children: [
                    if (widget.configurations.isNotEmpty)
                      Positioned.fill(
                        child: FutureBuilder<MechanicCarouselScene>(
                          future: _loading,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Caricamento 3D non riuscito:\n${snapshot.error}',
                                ),
                              );
                            }
                            final scene = snapshot.data!;
                            return IgnorePointer(
                              child: RepaintBoundary(
                                child: SceneView(
                                  scene.scene,
                                  camera: scene.camera,
                                  autoTick: !widget.isScrolling,
                                  // 90% on each axis: 19% fewer 3D pixels; UI stays native.
                                  pixelRatio:
                                      MediaQuery.devicePixelRatioOf(context) *
                                      .9,
                                  onTick: (_, deltaSeconds) =>
                                      scene.tick(deltaSeconds),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    AnimatedBuilder(
                      animation: _position,
                      builder: (context, _) => Stack(
                        children: [
                          for (
                            var i = 0;
                            i <= widget.configurations.length;
                            i++
                          )
                            MechanicCarouselLabel(
                              key: ValueKey('mechanic_slot_$i'),
                              place: MechanicCarouselLayout.at(
                                i - _position.value,
                              ),
                              width: constraints.maxWidth,
                              name: i == 0
                                  ? null
                                  : widget.configurations[i - 1].name,
                              showName: i == _selected,
                              plusPulse: i == 0 ? _plusPulse : null,
                              onTap: () {
                                if (i == _selected) {
                                  _open(i);
                                } else {
                                  _settle(i);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  void _open(int index) {
    if (_dragging || _position.isAnimating) return;
    if (index == 0) {
      widget.onAdd?.call();
    } else {
      widget.onOpen?.call(index);
    }
  }
}
