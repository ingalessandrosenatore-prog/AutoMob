import 'package:flutter/material.dart';

import '../../../../core/widgets/mechanic_search_bar.dart';

/// Campo di ricerca della lista veicoli.
///
/// Le callback rappresentano eventi di presentazione: il widget non conosce
/// il BLoC e quindi resta riutilizzabile senza introdurre dipendenze di stato.
class WorkshopSearchControls extends StatelessWidget {
  const WorkshopSearchControls({
    super.key,
    required this.enabled,
    required this.controller,
    required this.onSearchChanged,
    this.repaint,
    this.gradient,
  });

  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final Listenable? repaint;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return MechanicSearchBar(
      enabled: enabled,
      controller: controller,
      onChanged: onSearchChanged,
      hintText: 'Cerca targa, marca o modello...',
      repaint: repaint,
    );
  }
}
