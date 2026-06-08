import 'package:flutter/material.dart';
import 'AddVehicleWizard.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({super.key});

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
        child: Container(
          color: const Color(0xFF0F0F11),

          child: const AddVehicleWizard(),
        ),
      ),
      isScrollControlled: true,
    );
  }
}