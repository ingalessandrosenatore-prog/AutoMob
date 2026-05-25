import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A class representing an action in the Glass FAB menu.
class AmGlassAction {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  AmGlassAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

/// A custom Floating Action Button that expands into a glassmorphic menu.
class AmGlassFab extends StatefulWidget {
  final List<AmGlassAction> actions;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;

  const AmGlassFab({
    super.key,
    required this.actions,
    this.backgroundColor = const Color(0xFF1A1C23),
    this.activeColor = const Color(0xFFFF6B00),
    this.inactiveColor = const Color(0xFF8BA2D4),
  });

  @override
  State<AmGlassFab> createState() => _AmGlassFabState();
}

class _AmGlassFabState extends State<AmGlassFab> with TickerProviderStateMixin {
  bool _isOpen = false;

  late AnimationController _controller;
  late AnimationController _stretchController;

  // FASI DI APERTURA PURE (Senza più flash luminosi)
  late Animation<double> _swellAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  // FASE UNICA DI CHIUSURA
  late Animation<double> _closeAnimation;

  final ValueNotifier<double> _dragY = ValueNotifier(0.0);
  double _stretchStartValue = 0.0;

  late final Listenable _animationListenable;
  late final double _maxMenuHeight;
  late final Widget _cachedActionsList;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _stretchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_onStretchTick);

    // ==========================================
    // LOGICA DI APERTURA
    // ==========================================
    _swellAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 30
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(_controller);

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.30, 1.0, curve: Curves.easeOut)),
    );

    // ==========================================
    // LOGICA DI CHIUSURA
    // ==========================================
    _closeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
      reverseCurve: const Cubic(0.6, -0.15, 0.735, 0.045),
    );

    _animationListenable = Listenable.merge([_controller, _dragY]);
    _maxMenuHeight = 60.0 + (widget.actions.length * 55.0);
    _cachedActionsList = RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
        child: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in widget.actions)
                _AmGlassFabActionItem(action: action, onClose: _toggle),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stretchController.removeListener(_onStretchTick);
    _controller.dispose();
    _stretchController.dispose();
    _dragY.dispose();
    super.dispose();
  }

  void _onStretchTick() {
    final double t = Curves.elasticOut.transform(_stretchController.value);
    _dragY.value = lerpDouble(_stretchStartValue, 0.0, t)!;
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _controller.forward();
    } else {
      _dragY.value = 0.0;
      _controller.reverse();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isOpen) return;
    final double current = _dragY.value;
    final double resistance = 1.0 - (current.abs() / 200).clamp(0.0, 0.8);
    final double next = (current + details.delta.dy * 0.4 * resistance).clamp(-60.0, 120.0);
    _dragY.value = next;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isOpen) return;

    if (_dragY.value > 40.0) {
      _toggle();
      return;
    }

    _stretchStartValue = _dragY.value;
    _stretchController.stop();
    _stretchController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

        AnimatedBuilder(
          animation: _animationListenable,
          child: _cachedActionsList,
          builder: (context, child) {

            final bool isClosing = _controller.status == AnimationStatus.reverse;

            double dynamicWidth, dynamicHeight, dynamicRadius;
            double iconScale, safeExpand, currentRotation;

            if (isClosing) {
              final double closeValue = _closeAnimation.value;
              final double boundedClose = math.max(-0.02, closeValue);
              safeExpand = closeValue.clamp(0.0, 1.0);

              dynamicWidth = lerpDouble(60.0, 260.0, boundedClose)!;
              dynamicHeight = lerpDouble(60.0, _maxMenuHeight, boundedClose)!;
              dynamicRadius = lerpDouble(30.0, 32.0, boundedClose)!;

              iconScale = 1.0;
              currentRotation = safeExpand * 0.125 * 2 * math.pi;

            } else {
              final double swell = _swellAnimation.value;
              final double expand = _expandAnimation.value;
              safeExpand = expand.clamp(0.0, 1.0);

              dynamicWidth = 60.0 + (24.0 * swell) + (196.0 * expand);
              dynamicHeight = 60.0 + (24.0 * swell) + ((_maxMenuHeight - 84.0) * expand);
              dynamicRadius = 30.0 + (10.0 * swell) + ((32.0 - 40.0) * expand);

              iconScale = 1.0 + (0.25 * swell);
              currentRotation = _expandAnimation.value * 0.125 * 2 * math.pi;
            }

            final Color baseBgColor = Color.lerp(
                widget.backgroundColor,
                widget.backgroundColor!,
                safeExpand
            )!;

            final double dragY = _dragY.value;
            final bool showActions =
                _controller.status == AnimationStatus.completed;
            // ============= BAGLIORE ANIMATO =============
            // intensità: picco al 50% dell'animazione, va a 0 a inizio/fine
            final double glowIntensity = math.sin(safeExpand * math.pi);
            // centro: bottom-right in apertura, top-left in chiusura
            final Alignment glowCenter =
                isClosing ? Alignment.topLeft : Alignment.bottomRight;

            return Positioned(
              right: 0,
              bottom: 0,
              child: Transform(
                alignment: Alignment.bottomRight,
                transform: Matrix4.identity()
                  ..scale(
                    1.0 + (dragY.abs() * 0.0005),
                    1.0 - (dragY * 0.002),
                  ),
                child: RepaintBoundary(
                  child: GestureDetector(
                    onVerticalDragUpdate: _onPanUpdate,
                    onVerticalDragEnd: _onPanEnd,
                    child: Container(
                      width: dynamicWidth,
                      height: dynamicHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(dynamicRadius),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3 * (1.0 - safeExpand)),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3 * safeExpand),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(dynamicRadius),
                        child: Material(
                          color: baseBgColor, // Il colore di sfondo passa al Material
                          child: InkWell(
                            // Quando è aperto disattiviamo l'InkWell principale
                            onTap: _isOpen ? null : _toggle,
                            splashColor: widget.inactiveColor?.withOpacity(0.5), // L'onda chiara
                            highlightColor: Colors.white.withOpacity(0.25),
                            radius: 50,
                            hoverColor:  widget.inactiveColor?.withOpacity(0.5) ,
                            // Highlight morbidissimo
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [

                                // ============= OVERLAY BAGLIORE =============
                                if (glowIntensity > 0.01)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            center: glowCenter,
                                            radius: 1.4,
                                            colors: [
                                              widget.inactiveColor!
                                                  .withOpacity(0.45 * glowIntensity),
                                              widget.inactiveColor!
                                                  .withOpacity(0.10 * glowIntensity),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.45, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                if (showActions)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: child!,
                                  ),

                                Container(
                                  alignment: Alignment.center,
                                  width: 60,
                                  height: 60,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.add,
                                      color: Color.lerp(
                                          widget.inactiveColor,
                                          widget.inactiveColor?.withOpacity(0.5),
                                          safeExpand
                                      ),
                                      size:30,
                                    ),
                                    onPressed: _isOpen ? _toggle : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

}

class _AmGlassFabActionItem extends StatelessWidget {
  final AmGlassAction action;
  final VoidCallback onClose;

  const _AmGlassFabActionItem({
    required this.action,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onClose();
          action.onPressed();
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: action.color.withOpacity(0.1),
        highlightColor: action.color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: action.color.withOpacity(0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: action.color.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}