import 'package:flutter/material.dart';
import '../../../vehicle/domain/entities/mechanic_summary.dart';
import 'workshop_fallback_tile.dart';

/// Native, accessible fallback when the platform cannot create a 3D surface.
class WorkshopDepthFallback extends StatefulWidget {
  const WorkshopDepthFallback({
    super.key,
    required this.mechanics,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    required this.onOpen,
  });
  final List<MechanicSummary> mechanics;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<MechanicSummary> onOpen;
  @override
  State<WorkshopDepthFallback> createState() => _WorkshopDepthFallbackState();
}

class _WorkshopDepthFallbackState extends State<WorkshopDepthFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position;
  double _origin = 0, _drag = 0;
  int get _count => widget.mechanics.length;
  int _visual(int index) => index; //? _count : index - 1;
  int _data(int position) => position; // == _count ? 0 : position + 1;

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(
      vsync: this,
      value: _visual(widget.selected).toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant WorkshopDepthFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected ||
        oldWidget.mechanics.length != _count) {
      _settle(_visual(widget.selected));
    }
  }

  void _settle(int target) {
    _position.animateTo(
      target.toDouble(),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      return GestureDetector(
        key: const Key('workshop_carousel_drag'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _position.stop();
          _origin = _position.value;
          _drag = 0;
        },
        onHorizontalDragUpdate: (details) {
          _drag += details.primaryDelta ?? 0;
          _position.value = (_origin - _drag / (width * .42))
              .clamp(0, _count)
              .toDouble();
        },
        onHorizontalDragEnd: (_) {
          final target = _position.value.round().clamp(0, _count);
          _settle(target);
          widget.onSelect(_data(target));
        },
        onHorizontalDragCancel: () => _settle(_visual(widget.selected)),
        child: AnimatedBuilder(
          animation: _position,
          builder: (context, _) {
            final order = List.generate(_count + 1, (i) => i)
              ..sort(
                (a, b) => (_visual(b) - _position.value).abs().compareTo(
                  (_visual(a) - _position.value).abs(),
                ),
              );
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final index in order)
                  if ((_visual(index) - _position.value) >= -1.5 &&
                      (_visual(index) - _position.value) <= 2.5)
                    WorkshopFallbackTile(
                      key: ValueKey('workshop_tile_$index'),
                      mechanic: index == 0 ? null : widget.mechanics[index - 1],
                      active: index == widget.selected,
                      scale: _scale(_visual(index) - _position.value),
                      x:
                          width *
                              (.42 +
                                  _offset(_visual(index) - _position.value)) -
                          55,
                      top:
                          22 +
                          (1 - _scale(_visual(index) - _position.value)) * 45,
                      onTap: () {
                        if (widget.selected != index) {
                          widget.onSelect(index);
                        } else if (index == 0) {
                          widget.onAdd();
                        } else {
                          widget.onOpen(widget.mechanics[index - 1]);
                        }
                      },
                    ),
              ],
            );
          },
        ),
      );
    },
  );

  double _scale(double distance) => distance < 0
      ? (1 + distance * .28).clamp(.4, 1)
      : (distance <= 1 ? 1 - distance * .26 : .74 - (distance - 1) * .19).clamp(
          .4,
          1,
        );
  double _offset(double distance) => distance < 0
      ? distance * .21
      : distance <= 1
      ? distance * .31
      : .31 + (distance - 1) * .17;
}
