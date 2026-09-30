/// @brief Posizione interpolata tra i quattro slot del carosello.
/// @details Distanza 0 = slot 1 selezionato; -1 = slot 0 a sinistra;
/// +1 e +2 = slot 2 e 3 arretrati a destra. Gli estremi escono dalla vista.
class MechanicCarouselLayout {
  const MechanicCarouselLayout(this.x, this.scale, this.depth, this.opacity);
  final double x;
  final double scale;
  final double depth;
  final double opacity;

  static const _slots = [
    MechanicCarouselLayout(-.58, .45, 3, 0),
    MechanicCarouselLayout(-.35, .72, 1.4, 1),
    MechanicCarouselLayout(-.02, 1, 0, 1),
    MechanicCarouselLayout(.30, .74, 1.5, 1),
    MechanicCarouselLayout(.40, .55, 3, 1),
    MechanicCarouselLayout(.62, .40, 4.5, 0),
  ];

  static MechanicCarouselLayout at(double distance) {
    final value = (distance + 2).clamp(0.0, 5.0);
    final index = value.floor().clamp(0, 4);
    final t = value - index;
    final a = _slots[index], b = _slots[index + 1];
    double mix(double a, double b) => a + (b - a) * t;
    return MechanicCarouselLayout(
      mix(a.x, b.x),
      mix(a.scale, b.scale),
      mix(a.depth, b.depth),
      mix(a.opacity, b.opacity),
    );
  }
}
