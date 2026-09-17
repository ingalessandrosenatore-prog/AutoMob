import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
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

/// Adattatore provvisorio del package: mantiene fuori dal resto della
/// dashboard ogni decisione specifica di CardStackSwiper.
class AmWorkshopSwiper extends StatelessWidget {
  final List<MechanicSummary> mechanics;
  final VoidCallback onAdd;
  final ValueChanged<MechanicSummary> onMechanicTap;
  final controller = CardStackSwiperController();

  AmWorkshopSwiper({
    super.key,
    required this.mechanics,
    required this.onAdd,
    required this.onMechanicTap,
  });

  @override
  Widget build(BuildContext context) {
    // La prima card è sempre quella di aggiunta
    final items = <MechanicSummary?>[null, ...mechanics];

    return SizedBox(
      height: 140,
      width: 400,
      child: CardStackSwiper(
        controller: controller,
        cardsCount: items.length,
        onSwipe: (previousIndex, currentIndex, direction) {
          if (direction == CardStackSwiperDirection.left) return false;
          return true;
        },
        initialIndex: 0,
        isLoop: items.length > 1,
        isDisabled: items.length == 1,
        maxAngle: 0,
        backCardAngle: 0,
        backCardScale: 1,
        // Con 3 card totali e dx positivo, CardStackSwiper alterna
        // automaticamente il dx tra negativo (seconda card) e positivo (terza card).
        backCardOffset: const Offset(5, 0),
        threshold: 20,
        swipeAnimationDuration: const Duration(milliseconds: 400),
        returnAnimationDuration: const Duration(milliseconds: 400),
        allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
          horizontal: true,
        ),
        onTapDisabled: onAdd,
        onPressed: (index) {
          final mechanic = items[index];
          mechanic == null ? onAdd() : onMechanicTap(mechanic);
        },
        cardBuilder: (context, index, horizontal, vertical) {
          final mechanic = items[index];
          return mechanic == null
              ? AmWorkshopCard.add(onTap: onAdd)
              : AmWorkshopCard(
                  mechanic: mechanic,
                  onTap: () => onMechanicTap(mechanic),
                );
        },
      ),
    );
  }
}
