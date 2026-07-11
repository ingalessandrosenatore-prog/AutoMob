import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AmBannerBig extends StatelessWidget {
  final String? imagePath;
  final File? imageFile;
  final String? logoPath;
  final File? logoFile;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color buttonColor;
  final Color textColor;
  final Color shadowColor;

  const AmBannerBig({
    super.key,
    this.imagePath,
    this.imageFile,
    this.logoPath,
    this.logoFile,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    this.backgroundColor = const Color(0xFF2C2C2E),
    this.buttonColor = const Color(0xFF3192F3),
    this.textColor = Colors.white,
    this.shadowColor = Colors.black45,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 180,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: _BannerImage(path: imagePath, file: imageFile, fit: BoxFit.cover),
            ),
            // Blur / Grain / Bokeh effect overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Particles / Bokeh Mockup (Visual decoration)
            Positioned.fill(
              child: CustomPaint(
                painter: _BokehPainter(),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subtitle.toUpperCase(),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            elevation: 5,
                            shadowColor: buttonColor.withValues(alpha: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                buttonLabel,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: _BannerImage(path: logoPath, file: logoFile, fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class AmBannerSmall extends StatelessWidget {
  final String? imagePath;
  final File? imageFile;
  final String discount;
  final String brandName;
  final String productName;
  final String price;
  final String? oldPrice;
  final Widget? brandLogo;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color priceColor;

  const AmBannerSmall({
    super.key,
    this.imagePath,
    this.imageFile,
    required this.discount,
    required this.brandName,
    required this.productName,
    required this.price,
    this.oldPrice,
    this.brandLogo,
    required this.onTap,
    this.backgroundColor = const Color(0xFF1C1C1E),
    this.textColor = Colors.white,
    this.priceColor = const Color(0xFFFF6B00),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image part
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.white,
                    child: _BannerImage(
                      path: imagePath,
                      file: imageFile,
                      fit: BoxFit.contain,
                      fallback: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                // Discount Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D55),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2D55).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      discount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // AD Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AD',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            // Info part
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (brandLogo != null) ...[
                        brandLogo!,
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          brandName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: priceColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (oldPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          oldPrice!,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.3),
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Immagine di banner da file locale, URL o asset, con fallback quando
/// nessuna sorgente è disponibile.
class _BannerImage extends StatelessWidget {
  final String? path;
  final File? file;
  final BoxFit fit;
  final Widget fallback;

  const _BannerImage({
    required this.path,
    required this.file,
    required this.fit,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    if (file != null) return Image.file(file!, fit: fit);
    final p = path;
    if (p != null) {
      if (p.startsWith('http')) return Image.network(p, fit: fit);
      return Image.asset(p, fit: fit);
    }
    return fallback;
  }
}

class _BokehPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final random = math.Random(42);

    for (var i = 0; i < 15; i++) {
      final center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = random.nextDouble() * 40 + 10;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
