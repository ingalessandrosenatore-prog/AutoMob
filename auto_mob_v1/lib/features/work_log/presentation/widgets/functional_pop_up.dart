import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/add_work_log_pop_up.dart';
import 'package:flutter/material.dart';





class BottomSheetPageFunc<T> extends Page<T> {
  final EnumPopUp type;
  final String idVeicolo;
  final int currentKm;
  const BottomSheetPageFunc({
    super.key,
    required this.type,
    required this.idVeicolo,
    required this.currentKm,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (context) =>  ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          child: Container(
            color: const Color(0xFF0F0F11),

            child: switch(type) {

              EnumPopUp.aggiornaTagliando => AddWorkLogPopUp( initialWorkType: type, id: idVeicolo, currentKm: currentKm,),
              EnumPopUp.aggiornaDistribuzione =>  AddWorkLogPopUp( initialWorkType: type, id: idVeicolo, currentKm: currentKm,),

              EnumPopUp.aggiornaCambioGomme => AddWorkLogPopUp( initialWorkType: type, id: idVeicolo, currentKm: currentKm,),
              EnumPopUp.altro => AddWorkLogPopUp(initialWorkType: type, id: idVeicolo, currentKm: currentKm,),
              // TODO: Handle this case.
              EnumPopUp.revisione => throw UnimplementedError(),
              // TODO: Handle this case.
              EnumPopUp.pneumaticiInversione => throw UnimplementedError(),
            },
          ),
        ),

     isScrollControlled: true,
    );
  }
}
