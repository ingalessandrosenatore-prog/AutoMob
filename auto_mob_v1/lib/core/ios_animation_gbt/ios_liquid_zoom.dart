import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'ios_liquid_zoom_config.dart';
import 'ios_liquid_zoom_layout.dart';
import 'src/ios_liquid_light_painter.dart';

enum IosLiquidZoomPhase { idle, lifting, opening, open, closing, settling }

/// Handle opzionale per aprire e chiudere la transition da codice.
///
/// Lo stesso controller viene consegnato ai builder di sorgente e destinazione,
/// quindi un bottone nella destinazione può usare [close] come un normale pop.
class IosLiquidZoomController<T> extends ChangeNotifier {
  Future<T?> Function()? _openCallback;
  Future<void> Function(T? result)? _closeCallback;
  IosLiquidZoomPhase _phase = IosLiquidZoomPhase.idle;

  IosLiquidZoomPhase get phase => _phase;
  bool get isOpen => _phase != IosLiquidZoomPhase.idle;

  Future<T?> open() {
    final callback = _openCallback;
    if (callback == null) {
      return Future<T?>.error(
        StateError('IosLiquidZoomController non collegato a un widget.'),
      );
    }
    return callback();
  }

  Future<void> close([T? result]) {
    final callback = _closeCallback;
    if (callback == null) {
      return Future<void>.error(
        StateError('IosLiquidZoomController non collegato a un widget.'),
      );
    }
    return callback(result);
  }

  void _attach({
    required Future<T?> Function() open,
    required Future<void> Function(T? result) close,
  }) {
    assert(
      _openCallback == null,
      'Controller già collegato a un altro widget.',
    );
    _openCallback = open;
    _closeCallback = close;
  }

  void _detach() {
    _openCallback = null;
    _closeCallback = null;
    _setPhase(IosLiquidZoomPhase.idle);
  }

  void _setPhase(IosLiquidZoomPhase value) {
    if (_phase == value) return;
    _phase = value;
    notifyListeners();
  }
}

typedef IosLiquidSourceBuilder<T> =
    Widget Function(
      BuildContext context,
      IosLiquidZoomController<T> controller,
    );

typedef IosLiquidDestinationBuilder<T> =
    Widget Function(
      BuildContext context,
      IosLiquidZoomController<T> controller,
    );

/// Zoom transition riutilizzabile tra un trigger e una destinazione arbitraria.
///
/// Usa i builder quando la sorgente è già interattiva:
/// `sourceBuilder: (_, zoom) => Button(onPressed: zoom.open, ...)`.
class IosLiquidZoom<T> extends StatefulWidget {
  final IosLiquidSourceBuilder<T> sourceBuilder;
  final IosLiquidDestinationBuilder<T> destinationBuilder;
  final IosLiquidZoomLayout layout;
  final IosLiquidZoomConfig config;
  final IosLiquidZoomController<T>? controller;
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;

  const IosLiquidZoom({
    super.key,
    required this.sourceBuilder,
    required this.destinationBuilder,
    this.layout = const IosLiquidPageLayout(),
    this.config = const IosLiquidZoomConfig(),
    this.controller,
    this.onOpened,
    this.onClosed,
  });

  @override
  State<IosLiquidZoom<T>> createState() => _IosLiquidZoomState<T>();
}

/// Scorciatoia per card, icone o altri widget non ancora interattivi.
///
/// Per un vero [ButtonStyleButton] è preferibile [IosLiquidZoom], collegando
/// direttamente `controller.open` al suo `onPressed`.
class IosLiquidZoomTap<T> extends StatelessWidget {
  final Widget source;
  final Widget destination;
  final IosLiquidZoomLayout layout;
  final IosLiquidZoomConfig config;
  final IosLiquidZoomController<T>? controller;
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;
  final HitTestBehavior behavior;

  const IosLiquidZoomTap({
    super.key,
    required this.source,
    required this.destination,
    this.layout = const IosLiquidPageLayout(),
    this.config = const IosLiquidZoomConfig(),
    this.controller,
    this.onOpened,
    this.onClosed,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  Widget build(BuildContext context) {
    return IosLiquidZoom<T>(
      controller: controller,
      layout: layout,
      config: config,
      onOpened: onOpened,
      onClosed: onClosed,
      sourceBuilder: (context, zoom) => GestureDetector(
        behavior: behavior,
        onTap: () {
          zoom.open();
        },
        child: source,
      ),
      destinationBuilder: (context, zoom) => destination,
    );
  }
}

class _IosLiquidZoomState<T> extends State<IosLiquidZoom<T>>
    with SingleTickerProviderStateMixin {
  final GlobalKey _anchorKey = GlobalKey();
  final GlobalKey _snapshotKey = GlobalKey();
  late IosLiquidZoomController<T> _controller;
  late final AnimationController _liftController;
  _IosLiquidZoomRoute<T>? _activeRoute;
  Future<T?>? _activeFuture;
  ui.Image? _sourceSnapshot;
  bool _sourceHidden = false;
  bool _holdLift = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? IosLiquidZoomController<T>();
    _controller._attach(open: _open, close: _close);
    _liftController = AnimationController(
      vsync: this,
      duration: widget.config.liftDuration,
      reverseDuration: widget.config.liftDuration,
    );
  }

  @override
  void didUpdateWidget(IosLiquidZoom<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _liftController.duration = widget.config.liftDuration;
    _liftController.reverseDuration = widget.config.liftDuration;
    if (oldWidget.controller == widget.controller) return;

    _controller._detach();
    _controller = widget.controller ?? IosLiquidZoomController<T>();
    _controller._attach(open: _open, close: _close);
  }

  @override
  void dispose() {
    final route = _activeRoute;
    if (route != null) route.navigator?.removeRoute(route);
    _sourceSnapshot?.dispose();
    _sourceSnapshot = null;
    _controller._detach();
    _liftController.dispose();
    super.dispose();
  }

  Future<T?> _open() {
    final current = _activeFuture;
    if (current != null) return current;

    final completer = Completer<T?>();
    _activeFuture = completer.future;
    unawaited(_present(completer));
    return completer.future;
  }

  Future<void> _present(Completer<T?> completer) async {
    try {
      _holdLift = true;
      _controller._setPhase(IosLiquidZoomPhase.lifting);
      unawaited(_liftController.animateTo(1, curve: Curves.easeOutBack));
      await Future<void>.delayed(widget.config.liftLeadDuration);
      if (!mounted) return;

      final sourceRect = _readSourceRect();
      final liftedRect = sourceRect.shift(Offset(0, -widget.config.sourceLift));
      _sourceSnapshot = await _captureSource();
      if (!mounted) {
        _sourceSnapshot?.dispose();
        _sourceSnapshot = null;
        return;
      }

      setState(() => _sourceHidden = true);
      final route = _IosLiquidZoomRoute<T>(
        sourceRect: liftedRect,
        sourceSnapshot: _sourceSnapshot,
        destinationBuilder: widget.destinationBuilder,
        controller: _controller,
        layout: widget.layout,
        config: widget.config,
        onClosing: _handleRouteClosing,
      );
      _activeRoute = route;
      _controller._setPhase(IosLiquidZoomPhase.opening);

      unawaited(
        Future<void>.delayed(widget.config.transitionDuration, () {
          if (!mounted || _activeRoute != route) return;
          if (_controller.phase == IosLiquidZoomPhase.opening) {
            _controller._setPhase(IosLiquidZoomPhase.open);
            widget.onOpened?.call();
          }
        }),
      );

      final navigator = Navigator.of(
        context,
        rootNavigator: widget.config.useRootNavigator,
      );
      final result = await navigator.push<T>(route);
      await route.completed;
      _sourceSnapshot?.dispose();
      _sourceSnapshot = null;
      _activeRoute = null;

      if (mounted) {
        setState(() => _sourceHidden = false);
        _controller._setPhase(IosLiquidZoomPhase.settling);
        _holdLift = false;
        await _liftController.animateBack(0, curve: Curves.easeOutCubic);
        _controller._setPhase(IosLiquidZoomPhase.idle);
        widget.onClosed?.call();
      }
      completer.complete(result);
    } catch (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
      if (mounted) {
        setState(() => _sourceHidden = false);
        _holdLift = false;
        unawaited(_liftController.animateBack(0));
        _controller._setPhase(IosLiquidZoomPhase.idle);
      }
    } finally {
      _activeFuture = null;
    }
  }

  Future<void> _close(T? result) async {
    final route = _activeRoute;
    if (route == null) return;
    _controller._setPhase(IosLiquidZoomPhase.closing);
    route.navigator?.pop<T>(result);
    await (_activeFuture ?? Future<T?>.value());
  }

  void _handleRouteClosing() {
    if (_controller.phase != IosLiquidZoomPhase.closing) {
      _controller._setPhase(IosLiquidZoomPhase.closing);
    }
  }

  Rect _readSourceRect() {
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      throw StateError('Impossibile misurare il widget sorgente.');
    }
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  Future<ui.Image?> _captureSource() async {
    if (!widget.config.captureSource) return null;
    final renderObject = _snapshotKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary ||
        renderObject.debugNeedsPaint) {
      return null;
    }
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return renderObject.toImage(
      pixelRatio: devicePixelRatio.clamp(
        1,
        widget.config.maxSnapshotPixelRatio,
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activeRoute != null) return;
    _controller._setPhase(IosLiquidZoomPhase.lifting);
    unawaited(_liftController.animateTo(1, curve: Curves.easeOutBack));
  }

  void _handlePointerEnd(PointerEvent event) {
    Future<void>.microtask(() {
      if (!mounted || _holdLift || _activeRoute != null) return;
      unawaited(
        _liftController.animateBack(0, curve: Curves.easeOutCubic).whenComplete(
          () {
            if (mounted && _activeRoute == null) {
              _controller._setPhase(IosLiquidZoomPhase.idle);
            }
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.sourceBuilder(context, _controller);
    return Listener(
      key: _anchorKey,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: AnimatedBuilder(
        animation: _liftController,
        child: RepaintBoundary(
          key: _snapshotKey,
          child: IgnorePointer(
            ignoring: _sourceHidden,
            child: Opacity(opacity: _sourceHidden ? 0 : 1, child: source),
          ),
        ),
        builder: (context, child) {
          final lift = _liftController.value;
          final radius = widget.config.sourceBorderRadius;
          return Transform.translate(
            offset: Offset(0, -widget.config.sourceLift * lift),
            child: Transform.scale(
              scale: 1 + (widget.config.sourceScale - 1) * lift,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  child!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: radius,
                        child: CustomPaint(
                          painter: IosLiquidLightPainter(
                            progress: lift,
                            intensity:
                                widget.config.lightIntensity * lift * 0.52,
                            color: widget.config.lightColor,
                            origin: Alignment.center,
                            borderRadius: radius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IosLiquidZoomRoute<T> extends PageRouteBuilder<T> {
  final VoidCallback onClosing;

  _IosLiquidZoomRoute({
    required Rect sourceRect,
    required ui.Image? sourceSnapshot,
    required IosLiquidDestinationBuilder<T> destinationBuilder,
    required IosLiquidZoomController<T> controller,
    required IosLiquidZoomLayout layout,
    required IosLiquidZoomConfig config,
    required this.onClosing,
  }) : super(
         opaque: false,
         barrierColor: Colors.transparent,
         barrierDismissible: config.barrierDismissible,
         barrierLabel: config.barrierLabel,
         transitionDuration: config.transitionDuration,
         reverseTransitionDuration: config.reverseTransitionDuration,
         pageBuilder: (context, animation, secondaryAnimation) {
           return destinationBuilder(context, controller);
         },
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _IosLiquidZoomTransition(
             animation: animation,
             sourceRect: sourceRect,
             sourceSnapshot: sourceSnapshot,
             layout: layout,
             config: config,
             child: child,
           );
         },
       );

  @override
  bool didPop(T? result) {
    onClosing();
    return super.didPop(result);
  }
}

class _IosLiquidZoomTransition extends StatelessWidget {
  final Animation<double> animation;
  final Rect sourceRect;
  final ui.Image? sourceSnapshot;
  final IosLiquidZoomLayout layout;
  final IosLiquidZoomConfig config;
  final Widget child;

  const _IosLiquidZoomTransition({
    required this.animation,
    required this.sourceRect,
    required this.sourceSnapshot,
    required this.layout,
    required this.config,
    required this.child,
  });

  double _interval(double value, double begin, double end) {
    return ((value - begin) / (end - begin)).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final raw = animation.value.clamp(0.0, 1.0);
        final isClosing = animation.status == AnimationStatus.reverse;
        final curve = isClosing ? config.closingCurve : config.openingCurve;
        final morph = curve.transform(raw);
        final targetRect = layout.resolve(
          viewport: MediaQuery.sizeOf(context),
          safeArea: MediaQuery.viewPaddingOf(context),
          sourceRect: sourceRect,
        );
        final rect = Rect.lerp(sourceRect, targetRect, morph)!;
        final radiusProgress = morph.clamp(0.0, 1.0);
        final radius = BorderRadius.lerp(
          config.sourceBorderRadius,
          config.destinationBorderRadius,
          radiusProgress,
        )!;
        final contentProgress = _interval(raw, 0.12, 0.56);
        final sourceOpacity = 1 - _interval(raw, 0, 0.28);
        final backdropProgress = Curves.easeOutCubic.transform(raw);
        final lightPulse =
            (1 - (2 * raw - 1).abs()).clamp(0.0, 1.0) * config.lightIntensity;
        final origin = _originAlignment(sourceRect.center, targetRect);

        return Stack(
          fit: StackFit.expand,
          children: [
            _IosLiquidBackdrop(
              progress: backdropProgress,
              blur: config.backgroundBlur,
              color: config.barrierColor,
              dismissible: config.barrierDismissible,
            ),
            Positioned.fromRect(
              rect: rect,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: config.surfaceColor),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (sourceSnapshot != null)
                          Opacity(
                            opacity: sourceOpacity,
                            child: RawImage(
                              image: sourceSnapshot,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        OverflowBox(
                          alignment: origin,
                          minWidth: 0,
                          minHeight: 0,
                          maxWidth: double.infinity,
                          maxHeight: double.infinity,
                          child: SizedBox.fromSize(
                            size: targetRect.size,
                            child: IgnorePointer(
                              ignoring: raw < 0.98 || isClosing,
                              child: Opacity(
                                opacity: contentProgress,
                                child: ImageFiltered(
                                  imageFilter: ui.ImageFilter.blur(
                                    sigmaX:
                                        config.contentBlur *
                                        (1 - contentProgress),
                                    sigmaY:
                                        config.contentBlur *
                                        (1 - contentProgress),
                                  ),
                                  child: Transform.scale(
                                    alignment: origin,
                                    scale:
                                        config.contentStartScale +
                                        (1 - config.contentStartScale) *
                                            contentProgress,
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: CustomPaint(
                            painter: IosLiquidLightPainter(
                              progress: raw,
                              intensity: lightPulse,
                              color: config.lightColor,
                              origin: origin,
                              borderRadius: radius,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Alignment _originAlignment(Offset sourceCenter, Rect targetRect) {
    final relative = sourceCenter - targetRect.center;
    return Alignment(
      (relative.dx / (targetRect.width / 2)).clamp(-1.0, 1.0),
      (relative.dy / (targetRect.height / 2)).clamp(-1.0, 1.0),
    );
  }
}

class _IosLiquidBackdrop extends StatelessWidget {
  final double progress;
  final double blur;
  final Color color;
  final bool dismissible;

  const _IosLiquidBackdrop({
    required this.progress,
    required this.blur,
    required this.color,
    required this.dismissible,
  });

  @override
  Widget build(BuildContext context) {
    final backdrop = ColoredBox(
      color: Color.lerp(Colors.transparent, color, progress)!,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: dismissible
          ? () {
              Navigator.of(context).maybePop();
            }
          : null,
      child: blur == 0
          ? backdrop
          : BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: blur * progress,
                sigmaY: blur * progress,
              ),
              child: backdrop,
            ),
    );
  }
}
