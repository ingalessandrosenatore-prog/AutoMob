import 'dart:async';

import 'package:flutter/material.dart';

class WorkLogCardEntrance extends StatefulWidget {
  const WorkLogCardEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<WorkLogCardEntrance> createState() => _WorkLogCardEntranceState();
}

class _WorkLogCardEntranceState extends State<WorkLogCardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delay;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final delay = Duration(milliseconds: widget.index.clamp(0, 6) * 65);
    _delay = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        key: Key('work-log-card-entrance-${widget.index}'),
        position: Tween<Offset>(
          begin: const Offset(0.16, 0),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
