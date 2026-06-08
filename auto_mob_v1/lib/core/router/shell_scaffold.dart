import 'dart:math' as math;

import 'package:auto_mob_v1/core/widgets/Buttons/AmAnimatedNavButton.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// Voce della barra di navigazione.
class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class ShellScaffold extends StatefulWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold>
    with SingleTickerProviderStateMixin {
  // Aggiungere qui una voce (es. 'SERVIZI') la integra automaticamente nel
  // layout e nell'animazione della bolla. Max 3 voci: lo shader supporta
  // al massimo 4 forme di vetro per gruppo (bolla + voci).
  static const List<_NavItem> _items = [
    _NavItem(
      route: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'GARAGE',
    ),
    _NavItem(
      route: '/lavori',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      label: 'LAVORI',
    ),
    _NavItem(route: '/servizi', icon: Icons.list_sharp, activeIcon: Icons.list, label: 'SERVIZI')
  ];

  static const Color _accent = Color(0xFFFF6B00);
  // Sfondo del pill (niente più vetro qui). 0x1A000000 = nero ~10%.
  // Metti Colors.transparent per un pill completamente invisibile.
  static const Color _pillColor =  const Color(0xFF232326);

  late final AnimationController _controller;
  // Posizione orizzontale (alignment x, da -1 a 1) della bolla mobile.
  // Inizializzata inline (non `late`) per sopravvivere all'hot reload.
  Animation<double> _bubbleX = const AlwaysStoppedAnimation(0.0);
  int _index = 0;
  // Numero di "slot" saltati nel movimento corrente: scala la deformazione
  // (1.0 = salto tra due item adiacenti).
  double _stretchAmount = 0.0;
  // True mentre un item è premuto: fa lo scale del pill esterno.
  // ValueNotifier (non setState) così a cambiare è SOLO il pill, senza
  // rieseguire il build dello ShellScaffold.
  final ValueNotifier<bool> _pressed = ValueNotifier(false);

  // Geometria della barra, in px. Queste sono le manopole delle dimensioni.
  static const double _btnW = 100; // larghezza di ogni item
  static const double _gap = 6; // spazio tra gli item
  static const double _barH = 60; // altezza del pill
  static const double _bubbleW = _btnW; // = larghezza item: agli estremi la bolla combacia col bordo della pillola
  static const double _bubbleH = 60; // altezza a riposo della bolla

  // Larghezza del pill: si adatta ESATTAMENTE a item + spazi tra loro.
  double get _contentW => _items.length * _btnW + (_items.length - 1) * _gap;

  /// Centro orizzontale (px dal bordo sinistro) dell'item [i].
  double _centerFor(int i) => i * (_btnW + _gap) + _btnW / 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bubbleX = AlwaysStoppedAnimation(_centerFor(_index));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sincronizza la bolla con la rotta corrente (avvio o navigazione esterna),
    // così parte già centrata sull'item giusto senza animare.
    final location = GoRouterState.of(context).uri.path;
    final i = _items.indexWhere((e) => location.startsWith(e.route));
    if (i >= 0 && i != _index && !_controller.isAnimating) {
      _index = i;
      _bubbleX = AlwaysStoppedAnimation(_centerFor(i));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pressed.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    context.go(_items[i].route);
    if (i == _index) return;

    final begin = _bubbleX.value;
    final end = _centerFor(i);
    // Numero di slot saltati: scala la deformazione (1 = item adiacente).
    _stretchAmount = (end - begin).abs() / (_btnW + _gap);

    // Riparte dalla posizione attuale verso quella nuova.
    _bubbleX = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _index = i;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1C23),
      body: Stack(
        children: [
          RepaintBoundary(child: widget.child),

          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            // Center + niente width sul pill => il pill si adatta al contenuto
            // (_contentW) e resta centrato sullo schermo.
            child: Center(
              child: RepaintBoundary(
                // Il pill ora NON è più vetro: solo un Container traslucido,
                // ritagliato a pillola. Il liquid glass resta solo sulla bolla.
                child: ValueListenableBuilder<bool>(
                  valueListenable: _pressed,
                  // child costruito UNA volta sola e ri-usato: il rebuild tocca
                  // solo l'AnimatedScale, non l'intero pill/vetro.
                  builder: (context, pressed, child) => AnimatedScale(
                    scale: pressed ? 1.10 : 1.0,
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeOutCubic,
                    child: child,
                  ),
                  child: OCLiquidGlassGroup(
                  repaint: _controller,
                  settings: OCLiquidGlassSettings(
                  specStrength: 0,
                   blurRadiusPx: 3,
                    lightbandColor:  Colors.white10


                  ),
                  child: OCLiquidGlass( //barra
                    height: _barH,
                    enabled: false,
                    // Pillola larga ESATTAMENTE come il contenuto: così i bordi
                    // estremi coincidono con la bolla sul primo/ultimo item.
                    width: _contentW,
                    color:  const Color(0xFF232326).withOpacity(0.8),
                    borderRadius: 120,
                    child: Container(
                      child: Stack(
                        children: [
                          // Bolla mobile con effetto "gelatina", posizionata in px:
                          // a metà percorso si allunga in orizzontale e si abbassa
                          // in verticale, poi torna a riposo. sin(t·π)=0 agli
                          // estremi, 1 a metà.
                          // L'AnimatedBuilder è figlio DIRETTO dello Stack: solo
                          // così il Positioned applica left/top/width/height e la
                          // bolla arancione segue l'item selezionato.
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final s =
                                  math.sin(_controller.value * math.pi) *
                                  _stretchAmount;
                              final w = _bubbleW + s * 5; // allungo orizzontale
                              final h = (_bubbleH - s * 22).clamp(
                                40.0,
                                _bubbleH,
                              ); // schiaccio verticale
                              return Positioned(
                                left: _bubbleX.value - w / 2,
                                top: (_barH - h) / 2,
                                width: w,
                                height: h,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(0x4DEC4C0B),
                                    borderRadius: BorderRadius.circular(120),
                                  ),
                                  child: const OCLiquidGlass(
                                    borderRadius: 100,
                                    color: Color(0x2AFD6D2C),
                                    enabled: false,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Bottoni in fila: la fila definisce la larghezza
                          // del pill (item + spazi).
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < _items.length; i++) ...[
                                if (i > 0) const SizedBox(width: _gap),
                                AmAnimatedNavButton(
                                  icon: _items[i].icon,
                                  activeIcon: _items[i].activeIcon,
                                  label: _items[i].label,
                                  activeColor: _accent,
                                  isSelected: location.startsWith(
                                    _items[i].route,
                                  ),
                                  onPressChanged: (p) => _pressed.value = p,
                                  onTap: () => _onTap(i),
                                ),
                              ],
                            ],
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
        ],
      ),
    );
  }
}
