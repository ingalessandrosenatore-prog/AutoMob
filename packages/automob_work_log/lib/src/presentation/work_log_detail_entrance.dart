import 'package:flutter/material.dart';

typedef WorkLogDetailEntranceBuilder =
    Widget Function(BuildContext context, Animation<double> animation);

/// Un solo tempo guida foto, testi, contatore e tacche del dettaglio.
class WorkLogDetailEntrance extends StatefulWidget {
  const WorkLogDetailEntrance({required this.builder, super.key});

  final WorkLogDetailEntranceBuilder builder;

  @override
  State<WorkLogDetailEntrance> createState() => _WorkLogDetailEntranceState();
}

class _WorkLogDetailEntranceState extends State<WorkLogDetailEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

Animation<double> workLogEntranceInterval(
  Animation<double> parent,
  double begin,
  double end,
) => CurvedAnimation(
  parent: parent,
  curve: Interval(begin, end, curve: Curves.easeOutCubic),
);
