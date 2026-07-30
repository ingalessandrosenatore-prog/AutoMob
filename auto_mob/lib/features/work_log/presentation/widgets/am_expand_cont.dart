import 'package:auto_mob_v1/core/widgets/smart/smart_edge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../../../../core/config/performance_flags.dart';

/// CONTAINER ESPANDIBILE PERSONALIZZATO — niente ExpansionTile.
///
/// Tu controlli TUTTO:
///  - [collapsedHeight] / [expandedHeight]  -> l'altezza che vuoi
///  - [borderRadius]                        -> la forma
///  - il bounce dell'apertura (vedi _spring)
///
/// Un SOLO AnimationController guida una progressione 0->1 (_t).
/// Da _t deriviamo altezza, opacità contenuto e rotazione freccia.
class AmExpandableContainer extends StatefulWidget {
  final String title;
  final String subtitle;
  final double collapsedHeight;
  final double expandedHeight;
  final double borderRadius;
  final Widget child; // il contenuto (search bar + chip) lo passi da fuori

  const AmExpandableContainer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.collapsedHeight = 72,
    this.expandedHeight = 380,
    this.borderRadius = 16,
  });

  @override
  State<AmExpandableContainer> createState() => _AmExpandableContainerState();
}

class _AmExpandableContainerState extends State<AmExpandableContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl; // l'unico orologio 0..1
  bool _open = false;

  // molla dell'apertura: bounce basso = pop dolce, niente rimbalzi duri.
  static final SpringDescription _spring =
  SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 420),
    bounce: 10,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    _open = !_open;
    final sim = SpringSimulation(_spring, _ctrl.value, _open ? 1.0 : 0.0, 0);
    _ctrl.animateWith(sim);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value.clamp(0.0, 1.0); // progressione pulita 0..1

        // da _t deriviamo TUTTO (valori che TU decidi):
        final height = widget.collapsedHeight +
            (widget.expandedHeight - widget.collapsedHeight) * t;
        final contentOpacity = ((t - 0.15) / 0.85).clamp(0.0, 1.0); // entra dopo

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF29292B),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias, // taglia il contenuto ai bordi tondi
          child: SmartEdge(
            edges: [
              EdgeBlur(type: EdgeType.bottomEdge,
                  size: 30,
                  tintColor: Colors.black54,

                  sigma: 10, controlPoints:[
                    ControlPoint(position: 0.2, type: ControlPointType.visible),
                    ControlPoint(position: 1.0, type: ControlPointType.transparent),
                  ]
              )
            ],
            fallbackTint: Colors.black54, blur: kHeavyEffects,
            child: Column(
              children: [
                // ── HEADER (sempre visibile, cliccabile) ──────────────────
                InkWell(
                  onTap: _toggle,
                  child: SizedBox(
                    height: widget.collapsedHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.title,
                                    style: const TextStyle(
                                        color: Color(0xFF636366),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                Text(widget.subtitle,
                                    style: const TextStyle(
                                        color: Color(0xFF636366), fontSize: 12)),
                              ],
                            ),
                          ),
                          // freccia che ruota: rotazione derivata da _t
                          Transform.rotate(
                            angle: t * 3.14159, // 0 -> 180°
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowDown01,
                            color: Color(0xFF636366),
                            size: 24,
                            strokeWidth: 2.2,
                          ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── CONTENUTO (appare solo da aperto) ─────────────────────
                if (t > 0.01)
                  Expanded(
                    child: Opacity(
                      opacity: contentOpacity,
                      child: widget.child,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
