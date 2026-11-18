import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum VehicleHeroSlot { upperLeft, brakes, belowBrakes, lowerLeft, lowerRight }

class VehicleHeroLayout {
  VehicleHeroLayout({
    required double width,
    required List<({VehicleHeroSlot slot, double height})> items,
  }) {
    const inset = 12.0;
    const gap = 8.0;
    final available = math.max(0.0, width - inset * 2);
    final cardWidth = math.max(0.0, (available - gap) / 2).clamp(0.0, 212.0);
    final stageWidth = available.clamp(0.0, 600.0);
    final stageHeight = (stageWidth * .65).clamp(158.0, 340.0);
    viewport = Rect.fromLTWH(
      (width - stageWidth) / 2,
      items.isEmpty ? inset : 44,
      stageWidth,
      stageHeight,
    );

    final front = List<Rect>.filled(items.length, Rect.zero);
    double place(VehicleHeroSlot slot, double y, {required bool right}) {
      final width = switch (slot) {
        VehicleHeroSlot.belowBrakes => cardWidth * .82,
        VehicleHeroSlot.brakes => cardWidth * .86,
        _ => cardWidth,
      };
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        if (item.slot != slot) continue;
        front[index] = Rect.fromLTWH(
          right ? inset + available - width : inset,
          y,
          width,
          item.height,
        );
        y += item.height + gap;
      }
      return y;
    }

    final leftTop = place(VehicleHeroSlot.upperLeft, inset, right: false);
    final rearBottom = place(VehicleHeroSlot.belowBrakes, inset, right: true);
    final brakesBottom = place(
      VehicleHeroSlot.brakes,
      viewport.top + stageHeight * .62,
      right: true,
    );
    final lowerStart = viewport.bottom - 33;
    place(
      VehicleHeroSlot.lowerLeft,
      math.max(lowerStart - 17, leftTop),
      right: false,
    );
    place(VehicleHeroSlot.lowerRight, brakesBottom, right: true);

    final rear = List<Rect>.of(front);
    for (var index = 0; index < items.length; index++) {
      final rect = front[index];
      switch (items[index].slot) {
        case VehicleHeroSlot.brakes:
          rear[index] = Rect.fromLTWH(
            inset + cardWidth * .15,
            viewport.bottom - 15,
            rect.width,
            rect.height,
          );
        case VehicleHeroSlot.lowerRight:
          rear[index] = rect.translate(
            0,
            math.max(lowerStart, rearBottom) - rect.top,
          );
        case VehicleHeroSlot.belowBrakes:
          front[index] = rect.translate(3, 8);
        case VehicleHeroSlot.upperLeft:
        case VehicleHeroSlot.lowerLeft:
          break;
      }
    }

    height =
        [...front, ...rear].fold<double>(
          viewport.bottom,
          (bottom, rect) => math.max(bottom, rect.bottom),
        ) +
        inset;
    cards = List.unmodifiable(front);
    rearCards = List.unmodifiable(rear);
  }

  late final Rect viewport;
  late final double height;
  late final List<Rect> cards;
  late final List<Rect> rearCards;
}
