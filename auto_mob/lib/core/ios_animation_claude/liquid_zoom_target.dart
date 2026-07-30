import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Geometria di arrivo del morph: dato il rect del trigger e lo schermo,
/// decide dove atterra la card. Tre varianti pronte (pagina, modale, popup);
/// per casi particolari si può estendere questa classe e implementare
/// [resolve] a piacere.
abstract class LiquidZoomTarget {
  const LiquidZoomTarget();

  /// Pagina a schermo intero (meno un eventuale [margin]).
  const factory LiquidZoomTarget.page({EdgeInsets margin}) =
      LiquidZoomPageTarget;

  /// Modale di dimensione fissa ([width]/[height]) o proporzionale allo
  /// schermo ([widthFactor]/[heightFactor]), posizionato con [alignment].
  const factory LiquidZoomTarget.modal({
    double? width,
    double? height,
    double widthFactor,
    double heightFactor,
    Alignment alignment,
  }) = LiquidZoomModalTarget;

  /// Popup ancorato al trigger (stile pull-down): si apre dal bordo del
  /// trigger con direzione dinamica per non uscire dallo schermo.
  const factory LiquidZoomTarget.popup({
    required double width,
    required double height,
    double margin,
  }) = LiquidZoomPopupTarget;

  Rect resolve({required Rect source, required Size screen});
}

class LiquidZoomPageTarget extends LiquidZoomTarget {
  final EdgeInsets margin;

  const LiquidZoomPageTarget({this.margin = EdgeInsets.zero});

  @override
  Rect resolve({required Rect source, required Size screen}) =>
      margin.deflateRect(Offset.zero & screen);
}

class LiquidZoomModalTarget extends LiquidZoomTarget {
  final double? width;
  final double? height;
  final double widthFactor;
  final double heightFactor;
  final Alignment alignment;

  const LiquidZoomModalTarget({
    this.width,
    this.height,
    this.widthFactor = 0.92,
    this.heightFactor = 0.55,
    this.alignment = const Alignment(0, 0.4),
  });

  @override
  Rect resolve({required Rect source, required Size screen}) {
    final size = Size(
      width ?? screen.width * widthFactor,
      height ?? screen.height * heightFactor,
    );
    return alignment.inscribe(size, Offset.zero & screen);
  }
}

class LiquidZoomPopupTarget extends LiquidZoomTarget {
  final double width;
  final double height;
  final double margin;

  const LiquidZoomPopupTarget({
    required this.width,
    required this.height,
    this.margin = 8.0,
  });

  @override
  Rect resolve({required Rect source, required Size screen}) {
    // Direzione orizzontale dinamica: se non c'è spazio a destra del trigger
    // il popup si apre verso sinistra (bordo destro allineato al trigger).
    final double left;
    if (width + margin * 2 > screen.width) {
      left = margin;
    } else {
      final apreVersoSinistra = source.left + width > screen.width - margin;
      final naturale =
          apreVersoSinistra ? source.right - width : source.left;
      left = naturale.clamp(margin, screen.width - width - margin);
    }

    final maxTop = math.max(margin, screen.height - height - margin);
    final top = source.top.clamp(margin, maxTop);

    return Rect.fromLTWH(left, top, width, height);
  }
}
