import 'package:flutter/material.dart';
import 'AddVehicleWizard.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({super.key});

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      useSafeArea: true,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeInSine,
        duration: Duration(milliseconds: 500),
        reverseCurve: Curves.easeOut,
        reverseDuration: Duration(milliseconds: 500),
      ),
      backgroundColor: const Color(0xFF1A1C23),
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