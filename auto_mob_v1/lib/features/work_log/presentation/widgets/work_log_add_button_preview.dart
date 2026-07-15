import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/vehicle_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'work_log_add_button.dart';

class WorkLogAddButtonPreview extends StatelessWidget {
  @Preview(
    name: 'WorkLog · aggiungi lavoro',
    group: 'WorkLog',
    size: Size(390, 844),
    brightness: Brightness.dark,
  )
  const WorkLogAddButtonPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AmTheme.dark,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LAVORI'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WorkLogAddButton(
                vehicle: const VehicleOption(
                  id: 'preview-vehicle',
                  targa: 'AB123CD',
                  nome: 'Giulia',
                  brand: 'Alfa Romeo',
                  km: 42000,
                ),
                onMissingVehicle: _noop,
                onSaved: _noop,
                destinationBuilder: (context) => const _RegistrationPreview(),
              ),
            ),
          ],
        ),
        body: const Center(child: Text('Tocca + per aprire il wizard')),
      ),
    );
  }

  static void _noop() {}
}

class _RegistrationPreview extends StatelessWidget {
  const _RegistrationPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AGGIUNGI LAVORO'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Salva'),
        ),
      ),
    );
  }
}
