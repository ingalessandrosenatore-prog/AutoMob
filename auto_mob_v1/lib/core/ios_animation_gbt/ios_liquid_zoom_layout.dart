import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Calcola il rettangolo finale della destinazione nello spazio globale.
sealed class IosLiquidZoomLayout {
  const IosLiquidZoomLayout();

  Rect resolve({
    required Size viewport,
    required EdgeInsets safeArea,
    required Rect sourceRect,
  });
}

/// Destinazione a pagina intera.
final class IosLiquidPageLayout extends IosLiquidZoomLayout {
  final EdgeInsets insets;
  final bool respectSafeArea;

  const IosLiquidPageLayout({
    this.insets = EdgeInsets.zero,
    this.respectSafeArea = false,
  });

  @override
  Rect resolve({
    required Size viewport,
    required EdgeInsets safeArea,
    required Rect sourceRect,
  }) {
    final viewportRect = Offset.zero & viewport;
    final effectiveInsets = respectSafeArea ? insets + safeArea : insets;
    return effectiveInsets.deflateRect(viewportRect);
  }
}

/// Destinazione modale con dimensioni responsive e allineamento configurabile.
final class IosLiquidModalLayout extends IosLiquidZoomLayout {
  final Alignment alignment;
  final EdgeInsets margin;
  final double? width;
  final double? height;
  final double widthFactor;
  final double heightFactor;
  final double maxWidth;
  final double maxHeight;
  final bool respectSafeArea;

  const IosLiquidModalLayout({
    this.alignment = Alignment.bottomCenter,
    this.margin = const EdgeInsets.all(16),
    this.width,
    this.height,
    this.widthFactor = 1,
    this.heightFactor = 0.62,
    this.maxWidth = 640,
    this.maxHeight = double.infinity,
    this.respectSafeArea = true,
  }) : assert(width == null || width > 0),
       assert(height == null || height > 0),
       assert(widthFactor > 0 && widthFactor <= 1),
       assert(heightFactor > 0 && heightFactor <= 1),
       assert(maxWidth > 0),
       assert(maxHeight > 0);

  @override
  Rect resolve({
    required Size viewport,
    required EdgeInsets safeArea,
    required Rect sourceRect,
  }) {
    final safeInsets = respectSafeArea ? safeArea : EdgeInsets.zero;
    final available = (safeInsets + margin).deflateRect(Offset.zero & viewport);
    final resolvedWidth = math.min(
      width ?? available.width * widthFactor,
      math.min(maxWidth, available.width),
    );
    final resolvedHeight = math.min(
      height ?? available.height * heightFactor,
      math.min(maxHeight, available.height),
    );
    return alignment.inscribe(Size(resolvedWidth, resolvedHeight), available);
  }
}

/// Popup ancorato a un punto del widget sorgente.
final class IosLiquidPopupLayout extends IosLiquidZoomLayout {
  final Size size;
  final Alignment sourceAnchor;
  final Alignment destinationAnchor;
  final Offset offset;
  final EdgeInsets screenPadding;

  const IosLiquidPopupLayout({
    required this.size,
    this.sourceAnchor = Alignment.bottomCenter,
    this.destinationAnchor = Alignment.topCenter,
    this.offset = const Offset(0, 8),
    this.screenPadding = const EdgeInsets.all(8),
  });

  @override
  Rect resolve({
    required Size viewport,
    required EdgeInsets safeArea,
    required Rect sourceRect,
  }) {
    final sourcePoint =
        sourceRect.center +
        Offset(
          sourceAnchor.x * sourceRect.width / 2,
          sourceAnchor.y * sourceRect.height / 2,
        );
    final destinationDelta = Offset(
      (destinationAnchor.x + 1) * size.width / 2,
      (destinationAnchor.y + 1) * size.height / 2,
    );
    final desiredTopLeft = sourcePoint + offset - destinationDelta;
    final bounds = (safeArea + screenPadding).deflateRect(
      Offset.zero & viewport,
    );
    final left = desiredTopLeft.dx.clamp(
      bounds.left,
      math.max(bounds.left, bounds.right - size.width),
    );
    final top = desiredTopLeft.dy.clamp(
      bounds.top,
      math.max(bounds.top, bounds.bottom - size.height),
    );
    return Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      size.width,
      size.height,
    );
  }
}

typedef IosLiquidRectResolver =
    Rect Function(Size viewport, EdgeInsets safeArea, Rect sourceRect);

/// Escape hatch per layout non coperti da pagina, modale e popup.
final class IosLiquidCustomLayout extends IosLiquidZoomLayout {
  final IosLiquidRectResolver resolver;

  const IosLiquidCustomLayout(this.resolver);

  @override
  Rect resolve({
    required Size viewport,
    required EdgeInsets safeArea,
    required Rect sourceRect,
  }) {
    return resolver(viewport, safeArea, sourceRect);
  }
}
