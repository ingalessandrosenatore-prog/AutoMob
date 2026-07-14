import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/am_theme_colors.dart';

const String _engineAsset = 'lib/assets/icons/motore.svg';

/// Icona "motore" (SVG): stesso contratto visivo di un [Icon]
/// (size + color), usabile sia piccola che come watermark grande.
class AmEngineIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AmEngineIcon({super.key, required this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AmThemeColors.of(context).textPrimary;
    return SvgPicture.asset(
      _engineAsset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
    );
  }
}
