import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
import '../../bloc/vehicle_registration_bloc.dart';
import '../../bloc/vehicle_registration_event.dart';

/// Step 5 — foto del veicolo, ultimo step del flusso (solo in-memory: nessun
/// salvataggio reale su Supabase in questa fase, solo front-end).
///
/// Il bottone "Registra" vive nella barra fissa della pagina root; questo
/// widget espone [submit] tramite `GlobalKey<PhotoStepViewState>`.
class PhotoStepView extends StatefulWidget {
  const PhotoStepView({super.key});

  @override
  State<PhotoStepView> createState() => PhotoStepViewState();
}

class PhotoStepViewState extends State<PhotoStepView> {
  final _picker = ImagePicker();
  XFile? _image;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      // Stessi vincoli della modifica foto in home: niente 12MP inutili.
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _image = picked);
  }

  void submit() {
    context.read<VehicleRegistrationBloc>().add(
      PhotoStepSubmitted(fotoFile: _image != null ? File(_image!.path) : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AmEdgeBlur(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Foto del veicolo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aggiungi una foto per riconoscere subito il tuo veicolo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            _PhotoUploadCard(image: _image, onTap: _pickImage),
          ],
        ),
      ),
    );
  }
}

/// Card rettangolare con bordo tratteggiato per il caricamento della foto:
/// icona centrale, testo "Tocca per caricare" + sottotitolo formati.
class _PhotoUploadCard extends StatelessWidget {
  final XFile? image;
  final VoidCallback onTap;

  const _PhotoUploadCard({required this.image, required this.onTap});

  static const _accent = Color(0xFFE85A1A);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        foregroundPainter: _DashedBorderPainter(
          color: _accent.withValues(alpha: 0.5),
        ),
        child: Container(
          width: double.infinity,
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: image != null
              ? Image.file(
                  File(image!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth:
                      (MediaQuery.sizeOf(context).width *
                              MediaQuery.devicePixelRatioOf(context))
                          .round(),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                    // Nessun corrispettivo diretto trovato in HugeIcons 1.1.7.
                        icon: HugeIcons.strokeRoundedAlbum02,
                        color: _accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tocca per caricare',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'JPG, PNG fino a 10MB',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Bordo tratteggiato per un rettangolo arrotondato (nessun widget nativo in
/// Flutter per i bordi dashed).
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  static const _radius = 20.0;
  static const _dashWidth = 6.0;
  static const _dashGap = 4.0;
  static const _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );
    final metric = (Path()..addRRect(rrect)).computeMetrics().first;

    var distance = 0.0;
    while (distance < metric.length) {
      final next = distance + _dashWidth;
      canvas.drawPath(
        metric.extractPath(distance, next.clamp(0, metric.length)),
        paint,
      );
      distance = next + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
