import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widget/AddWorkLogPopUp.dart';
import 'package:flutter/material.dart';

import 'dart:ui';




class BottomSheetPageFunc<T> extends Page<T> {
  final EnumPopUp type;
  const BottomSheetPageFunc({super.key, required this.type});

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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: const Color(0xFF0F0F11).withOpacity(0.6),

            child: switch(type) {
              EnumPopUp.aggiornaKm => AddWorkLogPopUp(initialWorkType: type),
              EnumPopUp.aggiornaTagliando => AddWorkLogPopUp( initialWorkType: type),
              EnumPopUp.aggiornaDistribuzione =>  AddWorkLogPopUp( initialWorkType: type),
              EnumPopUp.aggiornaRevisione => AddWorkLogPopUp( initialWorkType: type),
              EnumPopUp.aggiornaCambioGomme => AddWorkLogPopUp( initialWorkType: type),
              EnumPopUp.altro => AddWorkLogPopUp(initialWorkType: type),
            },
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}