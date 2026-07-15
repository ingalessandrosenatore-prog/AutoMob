import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'ios_animation_gbt.dart';

class IosLiquidZoomPreview extends StatelessWidget {
  @Preview(
    name: 'Liquid zoom · modal',
    group: 'iOS animations',
    size: Size(390, 844),
    brightness: Brightness.dark,
  )
  const IosLiquidZoomPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: IosLiquidZoomTap<void>(
            layout: IosLiquidModalLayout(
              height: 420,
              margin: EdgeInsets.all(20),
            ),
            config: IosLiquidZoomConfig(
              surfaceColor: Color(0xFF242428),
              barrierColor: Color(0x66000000),
            ),
            source: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFF48A37),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 58,
                child: Icon(Icons.add_rounded, size: 30),
              ),
            ),
            destination: _PreviewModal(),
          ),
        ),
      ),
    );
  }
}

class _PreviewModal extends StatelessWidget {
  const _PreviewModal();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF242428),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Liquid zoom',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Il contenuto entra sfocato, si mette a fuoco e torna nel '
              'trigger con la transizione inversa.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
  }
}
