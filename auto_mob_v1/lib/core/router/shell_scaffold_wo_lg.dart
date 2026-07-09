import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

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
    with TickerProviderStateMixin {
  late final AnimationController bounceCtrl;
  late final AnimationController lightCtrl;

  final ValueNotifier<Offset?> _tapPositionNotifier =
  ValueNotifier<Offset?>(null);

  // ── CAMPIONAMENTO COLORE ────────────────────────────────────────────
  // CHIAVE: la GlobalKey sul RepaintBoundary è ciò che permette al
  // wrapper di "sbirciare" il contenuto senza che le pagine lo sappiano.
  final GlobalKey _contentKey = GlobalKey();

  // I due colori campionati (metà sinistra e metà destra della zona
  // dietro la pillola). La barra è l'UNICO widget in ascolto: quando
  // cambiano si ridipinge solo lei, mai la pagina.
  final ValueNotifier<List<Color>> _tintColors = ValueNotifier<List<Color>>(
    const [Color(0xFF16161A), Color(0xFF16161A)],
  );

  DateTime _lastSample = DateTime.fromMillisecondsSinceEpoch(0);
  bool _sampling = false; // evita catture sovrapposte

  static final SpringDescription _springDescription =
  SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 300),
    bounce: 0.1,
  );

  static final SpringDescription _lightDescription =
  SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 250),
    bounce: 0,
  );

  static const List<_NavItem> _items = [
    _NavItem(
      route: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_filled,
      label: 'GARAGE',
    ),
    _NavItem(
      route: '/lavori',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      label: 'LAVORI',
    ),
    _NavItem(
      route: '/servizi',
      icon: Icons.list_sharp,
      activeIcon: Icons.list,
      label: 'SERVIZ',
    ),
  ];

  @override
  void initState() {
    super.initState();
    bounceCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
    lightCtrl = AnimationController(vsync: this, value: 0.0);

    // Genera la texture di grana UNA volta sola (statica: se la
    // rigenerassi a ogni frame avresti l'effetto "neve della TV").
    _GrainTexture.ensure().then((_) {
      if (mounted) setState(() {});
    });

    // Prima cattura dopo il primo frame, così la pillola parte già
    // intonata col contenuto invece che col colore di fallback.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sampleColors());
  }

  @override
  void dispose() {
    bounceCtrl.dispose();
    lightCtrl.dispose();
    _tapPositionNotifier.dispose();
    _tintColors.dispose();
    super.dispose();
  }

  // ── PIPELINE: scroll → throttle → cattura ───────────────────────────
  // Le ScrollNotification risalgono l'albero DA SOLE da qualunque lista
  // in qualunque pagina: zero accoppiamento con le pagine.
  bool _onScroll(ScrollNotification n) {
    final now = DateTime.now();
    final throttleOk =
        now.difference(_lastSample) > const Duration(milliseconds: 120);

    // Campiona ogni 120ms durante lo scroll (max ~8 volte/sec)
    // e SEMPRE a scroll finito, così la tinta finale è precisa.
    if (n is ScrollEndNotification || throttleOk) {
      _lastSample = now;
      _sampleColors();
    }
    return false; // non consumare la notifica: le pagine non si accorgono di nulla
  }

  // Cattura un "francobollo" del contenuto e media i pixel dietro la barra.
  Future<void> _sampleColors() async {
    if (_sampling) return; // una cattura alla volta
    _sampling = true;
    try {
      final boundary = _contentKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize || boundary.debugNeedsPaint) {
        return;
      }

      final size = boundary.size;
      // CHIAVE DEL COSTO: pixelRatio minuscolo → immagine ~40px di
      // larghezza. Stiamo leggendo ~800 pixel, non 2,5 milioni.
      final pr = 40 / size.width;
      final ui.Image image = await boundary.toImage(pixelRatio: pr);
      final ByteData? bytes =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) {
        image.dispose();
        return;
      }

      final w = image.width;
      final h = image.height;

      // Geometria della pillola (stesse formule del build) proiettata
      // sul francobollo: campioniamo SOLO la striscia dietro la barra.
      final margine = (size.width * 15) / 100;
      final larghezzaBarra =
      math.min(size.width - 2 * margine, 500.0);
      final left0 = (margine * pr).floor().clamp(0, w - 1);
      final colN = math.max(2, (larghezzaBarra * pr).floor());
      final right0 = math.min(left0 + colN, w);
      final top0 = (((size.height - 24 - 58) * pr).floor()).clamp(0, h - 1);
      final bot0 = (((size.height - 24) * pr).ceil()).clamp(top0 + 1, h);

      final mid = left0 + (right0 - left0) ~/ 2;
      int rL = 0, gL = 0, bL = 0, nL = 0;
      int rR = 0, gR = 0, bR = 0, nR = 0;

      for (var y = top0; y < bot0; y++) {
        for (var x = left0; x < right0; x++) {
          final i = (y * w + x) * 4; // formato rawRgba: 4 byte per pixel
          final r = bytes.getUint8(i);
          final g = bytes.getUint8(i + 1);
          final b = bytes.getUint8(i + 2);
          if (x < mid) {
            rL += r; gL += g; bL += b; nL++;
          } else {
            rR += r; gR += g; bR += b; nR++;
          }
        }
      }
      image.dispose(); // libera SUBITO la memoria GPU del francobollo

      if (nL == 0 || nR == 0) return;
      _tintColors.value = [
        Color.fromARGB(255, rL ~/ nL, gL ~/ nL, bL ~/ nL),
        Color.fromARGB(255, rR ~/ nR, gR ~/ nR, bR ~/ nR),
      ];
    } finally {
      _sampling = false;
    }
  }

  // ── RICETTA "PATINA" (stile Telegram chiaro) ────────────────────────
  // Niente velo scuro e niente desaturazione: il colore campionato viene
  // SCHIARITO (+18% lightness) e leggermente saturato (+15%), così la
  // pillola sembra la versione retroilluminata dello sfondo che ha sotto.
  Color _patina(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withSaturation((hsl.saturation * 1.3).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0))
        .toColor();
  }

  void _onRelease() {
    bounceCtrl.animateWith(
        SpringSimulation(_springDescription, bounceCtrl.value, 1, 0));
    lightCtrl.animateWith(
        SpringSimulation(_lightDescription, lightCtrl.value, 0, 0));
  }

  void _onPress() {
    bounceCtrl.animateWith(
        SpringSimulation(_springDescription, bounceCtrl.value, 1.05, 0));
    lightCtrl.animateWith(
        SpringSimulation(_lightDescription, lightCtrl.value, 0.5, 0));
  }

  void _goTo(int index) {
    if (index < 0 || index >= _items.length) return;
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    // Indice attivo derivato dalla route: una sola fonte di verità,
    // niente più isSelect1/2/3 da tenere sincronizzati a mano.
    var selected = _items.indexWhere((it) => location.startsWith(it.route));
    if (selected == -1) selected = 0;

    final larghezzaSchermo = MediaQuery.sizeOf(context).width;
    final margine = (larghezzaSchermo * 15) / 100;
    const maxLarghezza = 500.0;
    final larghezzaBarra =
    math.min(larghezzaSchermo - 2 * margine, maxLarghezza);

    return Scaffold(
      body: Stack(
        children: [
          // Le pagine vivono qui dentro, ignare di tutto.
          // Il NotificationListener intercetta gli scroll che risalgono.
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: RepaintBoundary(
              key: _contentKey,
              child: widget.child,
            ),
          ),

          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (event) {
                _onPress();
                _tapPositionNotifier.value = event.localPosition;
              },
              onPanUpdate: (event) {
                _tapPositionNotifier.value = event.localPosition;
              },
              onPanEnd: (event) {
                final dito = _tapPositionNotifier.value;
                if (dito != null) {
                  // Il pan si conclude su un item: naviga davvero.
                  final itemWidth = larghezzaBarra / 3;
                  // localPosition è relativa al GestureDetector (tutto
                  // lo schermo in larghezza): riportala dentro la barra.
                  final inBar =
                      dito.dx - (larghezzaSchermo - larghezzaBarra) / 2;
                  final indice =
                  (inBar / itemWidth).floor().clamp(0, _items.length - 1);
                  _goTo(indice);
                }
                _onRelease();
              },
              onPanCancel: () {
                _onRelease();
                _tapPositionNotifier.value = null;
              },
              child: Center(
                child: SizedBox(
                  width: larghezzaBarra,
                  height: 58,
                  // Lo spring del "bounce" scala la pillola intera.
                  child: AnimatedBuilder(
                    animation: bounceCtrl,
                    builder: (context, child) => Transform.scale(
                      scale: bounceCtrl.value,
                      child: child,
                    ),
                    child: _AmGlassPill(
                      tintColors: _tintColors,
                      patina: _patina,
                      grainOpacity: 0, // ← la tua grana al 5%
                      lightCtrl: lightCtrl,
                      tapPosition: _tapPositionNotifier,
                      child: Row(
                        children: List.generate(_items.length, (i) {
                          final item = _items[i];
                          return AmNavItem(
                            icon: item.icon,
                            iconIsActive: item.activeIcon,
                            iconColor: Colors.white,
                            iconSize: 26,
                            iconColoractive: const Color(0xFF3192F3),
                            lable: item.label,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            textColor: Colors.white,
                            textColorIsActive: const Color(0xFF3192F3),
                            background: Colors.transparent,
                            backgorundIsActive:
                            const Color(0xFF3192F3).withValues(alpha: 0.3),
                            onTap: () => _goTo(i),
                            isSelect: selected == i,
                          );
                        }),
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

/// La pillola "fake glass": tinta campionata + riflesso + grana + bordo.
/// Quattro layer dichiarativi, ZERO BackdropFilter, zero saveLayer.
class _AmGlassPill extends StatelessWidget {
  final ValueNotifier<List<Color>> tintColors;
  final Color Function(Color) patina;
  final double grainOpacity;
  final AnimationController lightCtrl;
  final ValueNotifier<Offset?> tapPosition;
  final Widget child;

  const _AmGlassPill({
    required this.tintColors,
    required this.patina,
    required this.grainOpacity,
    required this.lightCtrl,
    required this.tapPosition,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder: quando i colori campionati cambiano si
    // ricostruisce SOLO questo sottoalbero (la pillola), non la pagina.
    return ValueListenableBuilder<List<Color>>(
      valueListenable: tintColors,
      builder: (context, colors, staticChild) {
        final l = patina(colors[0]);
        final r = patina(colors[1]);
        // ── IL TRUCCO DEL BORDO NON-UNIFORME ──────────────────────────
        // Flutter vieta Border con lati diversi + borderRadius. Quindi il
        // "bordo" non è un Border: è un layer ESTERNO riempito con un
        // gradiente verticale, e la pillola vera ci sta dentro con 1.3px
        // di padding. La fessura scoperta È il bordo: forte in alto,
        // quasi nullo ai lati (centro verticale), medio in basso.
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.80), // rim alto acceso
                Colors.white.withValues(alpha: 0.06), // lati quasi invisibili
                Colors.white.withValues(alpha: 0.40), // rim basso medio
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: const [

            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.3), // spessore del rim
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                // La patina campionata: sinistra→destra, segue il contenuto
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    l.withValues(alpha: 0.88),
                    r.withValues(alpha: 0.88),
                  ],
                ),
              ),
              child: staticChild,
            ),
          ),
        );
      },
      // Tutto ciò che NON dipende dai colori campionati sta qui: viene
      // costruito una volta sola e riusato a ogni cambio tinta.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Stack(
          children: [
            // LAYER 2 — riflesso verticale fisso (la "curvatura" del vetro)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.05),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // LAYER 3 — grana statica al 5%, blendMode.overlay:
            // schiarisce/scurisce il colore sotto invece di "sporcarlo"
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: GrainPainter(opacity: grainOpacity),
                ),
              ),
            ),

            // Glow del tocco — ora ascolta ANCHE tapPosition, così
            // durante il pan si ridisegna seguendo il dito.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: Listenable.merge([lightCtrl, tapPosition]),
                  builder: (context, _) => CustomPaint(
                    painter: GlowPainter(
                      intensity: lightCtrl.value,
                      color: Colors.white,
                      tapPosition: tapPosition.value,
                    ),
                  ),
                ),
              ),
            ),

            child,
          ],
        ),
      ),
    );
  }
}

/// Texture di rumore 64×64 generata UNA volta (seed fisso = grana statica).
class _GrainTexture {
  static ui.Image? image;

  static Future<void> ensure() async {
    if (image != null) return;
    const s = 64;
    final rnd = math.Random(42);
    final pixels = Uint8List(s * s * 4);
    for (var i = 0; i < s * s; i++) {
      final v = rnd.nextInt(256); // rumore monocromatico
      pixels[i * 4] = v;
      pixels[i * 4 + 1] = v;
      pixels[i * 4 + 2] = v;
      pixels[i * 4 + 3] = 255;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        pixels, s, s, ui.PixelFormat.rgba8888, completer.complete);
    image = await completer.future;
  }
}

/// Dipinge la grana come ImageShader tiled: un sample di texture già in
/// cache GPU, costo irrisorio. BlendMode.overlay su una draw op normale
/// NON crea saveLayer.
class GrainPainter extends CustomPainter {
  final double opacity;

  GrainPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final img = _GrainTexture.image;
    if (img == null || opacity <= 0) return;

    final paint = Paint()
      ..shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
    // Modula l'opacità della texture (il paint.color è ignorato dagli shader)
      ..colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: opacity),
        BlendMode.modulate,
      )
      ..blendMode = BlendMode.overlay;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(size.height / 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class AmNavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconIsActive;
  final Color iconColor;
  final double iconSize;
  final Color iconColoractive;
  final String lable;
  final FontWeight fontWeight;
  final double fontSize;
  final Color textColor;
  final Color textColorIsActive;
  final Color background;
  final Color backgorundIsActive;
  final GestureTapCallback? onTap;
  final bool isSelect;

  const AmNavItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.iconColoractive,
    required this.lable,
    required this.fontWeight,
    required this.textColor,
    required this.textColorIsActive,
    required this.background,
    required this.backgorundIsActive,
    required this.fontSize,
    required this.onTap,
    required this.isSelect,
    required this.iconIsActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: isSelect ? backgorundIsActive : background,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelect ? iconIsActive : icon,
                size: iconSize,
                color: isSelect ? iconColoractive : iconColor,
              ),
              Text(
                lable,
                style: TextStyle(
                  fontWeight: fontWeight,
                  fontSize: fontSize,
                  color: isSelect ? textColorIsActive : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlowPainter extends CustomPainter {
  final double intensity;
  final Color color;
  final Offset? tapPosition;

  GlowPainter({required this.intensity, required this.color, this.tapPosition});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final paint = Paint();
    paint.blendMode = BlendMode.plus;
    final centro = color.withValues(alpha: 0.50 * intensity);
    final meta = color.withValues(alpha: 0.40 * intensity);
    final bordi = color.withValues(alpha: 0.3 * intensity);
    List<Color> colors = [centro, meta, bordi];
    final rect = Offset.zero & size;

    // 2. Creiamo il gradiente radiale che si espande dal centro di questo rettangolo
    paint.shader = RadialGradient(colors: colors).createShader(rect);

    // 3. Disegniamo un rettangolo arrotondato (Pillola).
    // Usando s.height / 2 come raggio, i bordi laterali saranno perfettamente curvi.
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));

    canvas.drawRRect(rrect, paint);

    /* Nota: Se volessi un VERO ovale geometrico (un'ellisse, non una pillola con i lati dritti),
     ti basterebbe sostituire le righe 3 con:
     c.drawOval(rect, paint);
    */
  }

  @override
  bool shouldRepaint(GlowPainter old) => old.intensity != intensity;
}
