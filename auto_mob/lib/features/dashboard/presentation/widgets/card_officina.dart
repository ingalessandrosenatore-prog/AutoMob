import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Card dell'officina collegata al veicolo attualmente selezionato.
class AmWorkshopCard extends StatelessWidget {
  final MechanicSummary? mechanic;
  final VoidCallback? onTap;
  final bool isAdd;

  const AmWorkshopCard({
    super.key,
    required this.mechanic,
    this.onTap,
    this.isAdd = false,
  });

  const AmWorkshopCard.add({super.key, this.onTap})
    : mechanic = null,
      isAdd = true;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final effectiveBackgroundColor = isLight
        ? colors.surface
        : colors.background;

    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
    );
    final descriptionStyle = TextStyle(fontSize: 11, color: colors.textPrimary);
    final superTitleStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: colors.textPrimary,
    );

    if (isAdd) {
      return Swipercard(
        titoloSuperiore: "",
        titolo: "Aggiungi officina",
        descrizione: "Collega un officina al tuo Veicolo",
        radius: 40,
        borderColor: colors.accent,
        backGroundColor: effectiveBackgroundColor,
        iconButton: HugeIcons.strokeRoundedAdd01,
        iconColor: colors.textPrimary,
        radiusButton: 100,
        imageWidth: 150,
        imageHeight: 120,
        imagePath: 'lib/assets/images/meccanico_ombra.png',
        titoloSuperioreStyle: superTitleStyle,
        titoloStyle: titleStyle,
        descrizioneStyle: descriptionStyle,
        onTap: onTap ?? () {},
      );
    }

    return Swipercard(
      titoloSuperiore: "",
      titolo: mechanic?.businessName.toUpperCase() ?? "Meccanico",
      descrizione:
          "Questa officina puo gestire"
          " il tuo veicolo",
      radius: 40,
      borderColor: colors.info,
      backGroundColor: effectiveBackgroundColor,
      iconButton: HugeIcons.strokeRoundedArrowRight01,
      iconColor: colors.textPrimary,
      radiusButton: 100,
      imageWidth: 150,
      imageHeight: 120,
      imagePath: 'lib/assets/images/auto.png',
      titoloSuperioreStyle: superTitleStyle,
      titoloStyle: titleStyle,
      descrizioneStyle: descriptionStyle,
      onTap: onTap ?? () {},
    );
  }
}
