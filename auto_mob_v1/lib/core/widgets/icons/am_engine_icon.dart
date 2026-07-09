import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _engineAsset = 'lib/assets/icons/motore.svg';

/// Icona "motore" (SVG): stesso contratto visivo di un [Icon]
/// (size + color), usabile sia piccola che come watermark grande.
class AmEngineIcon extends StatelessWidget {
  final double size;
  final Color color;

  const AmEngineIcon({super.key, required this.size, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _engineAsset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
