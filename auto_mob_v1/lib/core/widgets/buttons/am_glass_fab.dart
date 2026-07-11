import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';

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
  // ignore: unused_field -- debito tecnico, vedi docs/TECH_DEBT.md
  late Animation<double> _rotationAnimation;

  // FASE UNICA DI CHIUSURA
  late Animation<double> _closeAnimation;

  final ValueNotifier<double> _dragY = ValueNotifier(0.0);
  double _stretchStartValue = 0.0;

  late final Listenable _animationListenable;
  late final double _maxMenuHeight;

  @override
  void initState() {
    super.initState();

    // MODIFICA 1: Rallentata l'animazione per godersi l'effetto onda
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Rallentato da 300 a 800
      reverseDuration: const Duration(milliseconds: 400),
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
    AmHaptics.tap();
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
          builder: (context, _) {

            final bool isClosing = _controller.status == AnimationStatus.reverse;

            double dynamicWidth, dynamicHeight, dynamicRadius;
            // ignore: unused_local_variable -- debito tecnico, vedi docs/TECH_DEBT.md
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
              dynamicRadius = 50.0 + (10.0 * swell) + ((32.0 - 40.0) * expand);

              iconScale = 1.0 + (0.25 * swell);
              currentRotation = _expandAnimation.value * 0.125 * 2 * math.pi;
            }

            final Color baseBgColor = Color.lerp(
                widget.backgroundColor,
                widget.backgroundColor!,
                safeExpand
            )!;

            final double dragY = _dragY.value;
            final bool showActions = safeExpand > 0.05;

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
                  // ignore: deprecated_member_use -- debito tecnico, vedi docs/TECH_DEBT.md
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
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3 * (1.0 - safeExpand)),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3 * safeExpand),
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
                            splashColor: widget.inactiveColor?.withValues(alpha: 0.5), // L'onda chiara
                            highlightColor: Colors.white.withValues(alpha: 0.25),
                            radius: 50,
                            hoverColor:  widget.inactiveColor?.withValues(alpha: 0.5) ,
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
                                                  .withValues(alpha: 0.45 * glowIntensity),
                                              widget.inactiveColor!
                                                  .withValues(alpha: 0.10 * glowIntensity),
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
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
                                      child: SizedBox(
                                        width: 260,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (int i = 0; i < widget.actions.length; i++)
                                              Builder(
                                                  builder: (context) {
                                                    // MODIFICA 2: Inversione dell'indice per far partire prima gli elementi in basso
                                                    int reversedIndex = widget.actions.length - 1 - i;

                                                    return _AmGlassFabActionItem(
                                                      action: widget.actions[i],
                                                      onClose: _toggle,
                                                      animation: CurvedAnimation(
                                                        parent: _controller,
                                                        curve: Interval(
                                                          0.4 + (reversedIndex * 0.1).clamp(0.0, 0.5),
                                                          1.0,
                                                          curve: Curves.easeOutBack, // Questo curva genera il "rimbalzo"
                                                        ),
                                                      ),
                                                    );
                                                  }
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
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
                                          widget.inactiveColor?.withValues(alpha: 0.5),
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
  final Animation<double> animation;

  const _AmGlassFabActionItem({
    required this.action,
    required this.onClose,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // MODIFICA 3: Aggiunta la transizione Y per l'effetto onda e il rimbalzo fisico
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.8), // Parte dal basso
      end: Offset.zero, // Arriva in posizione naturale
    ).animate(animation);

    return SlideTransition(
      position: offsetAnimation, // Movimento verticale
      child: ScaleTransition(
        scale: animation, // Movimento in profondità
        child: FadeTransition(
          opacity: animation, // Apparizione graduale
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AmHaptics.tap();
                onClose();
                action.onPressed();
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: action.color.withValues(alpha: 0.1),
              highlightColor: action.color.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: action.color.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: action.color.withValues(alpha: 0.05),
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
          ),
        ),
      ),
    );
  }
}