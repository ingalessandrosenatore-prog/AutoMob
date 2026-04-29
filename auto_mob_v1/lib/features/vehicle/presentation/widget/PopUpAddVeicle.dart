import 'package:flutter/material.dart';
import 'AddVehicleWizard.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({super.key});

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F11),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (context) => const AddVehicleWizard(),
    );
  }
}