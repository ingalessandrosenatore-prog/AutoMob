import 'package:flutter/material.dart';

class AmAnimatedNavButton extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool initialIsClicked;
  // Se fornito, il bottone è controllato dall'esterno e non toggling da solo.
  final bool? isSelected;

  const AmAnimatedNavButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.activeColor = const Color(0xFF4A90E2),
    this.onTap,
    this.initialIsClicked = false,
    this.isSelected,
  });

  @override
  State<AmAnimatedNavButton> createState() => _AmAnimatedNavButtonState();
}

class _AmAnimatedNavButtonState extends State<AmAnimatedNavButton>
    with SingleTickerProviderStateMixin {
  bool _isClicked = false;
  AnimationController? _bounceController;
  Animation<double> _scaleAnim = const AlwaysStoppedAnimation(1.0);

  @override
  void initState() {
    super.initState();
    _isClicked = widget.isSelected ?? widget.initialIsClicked;

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.91), weight: 28),
      TweenSequenceItem(
        tween: Tween(begin: 0.91, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 72,
      ),
    ]).animate(_bounceController!);
  }

  @override
  void dispose() {
    _bounceController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AmAnimatedNavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != null && widget.isSelected != _isClicked) {
      setState(() => _isClicked = widget.isSelected!);
      _bounceController?.forward(from: 0);
    }
  }

  void _handleTap() {
    if (widget.isSelected == null) {
      setState(() => _isClicked = !_isClicked);
    }
    _bounceController?.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isClicked ? widget.activeColor : const Color(0xFF131315).withOpacity(0.1),
              borderRadius: BorderRadius.circular(120),
              border: Border.all(
                color: _isClicked
                    ? widget.activeColor
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                if (_isClicked)
                  BoxShadow(
                    color: widget.activeColor.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isClicked ? widget.activeIcon : widget.icon,
                    color: _isClicked ? Colors.white : const Color(0xFF636366),
                    size: 26,
                  ),
                  if (_isClicked) ...[
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
