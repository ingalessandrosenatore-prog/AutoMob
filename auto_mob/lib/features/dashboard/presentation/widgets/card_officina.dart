import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';

const _workshopCardSmoothing = 0.8;

SmoothRectangleBorder _workshopShape({double radius = 22}) =>
    SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: _workshopCardSmoothing,
      ),
    );

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
    final currentMechanic = mechanic;
    final connected = currentMechanic != null;
    final accent = connected ? colors.info : colors.danger;

    return Semantics(
      button: onTap != null,
      label: connected
          ? 'Dettagli meccanico ${currentMechanic.businessName}'
          : isAdd
          ? 'Aggiungi officina'
          : 'Nessun meccanico collegato',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: _workshopShape(),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: colors.surface,
              shape: _workshopShape().copyWith(
                side: BorderSide(color: colors.border),
              ),
              shadows: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.09),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: ShapeDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: _workshopShape(radius: 14),
                  ),
                  child: HugeIcon(
                    icon: isAdd
                        ? HugeIcons.strokeRoundedAdd01
                        : HugeIcons.strokeRoundedArrowRight01,
                    color: accent,
                    size: 24,
                    strokeWidth: 2.2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdd ? 'Nuovo collegamento' : 'La tua officina',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentMechanic?.businessName ??
                            (isAdd
                                ? 'Aggiungi officina'
                                : 'Nessuna officina collegata'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Adattatore provvisorio del package: mantiene fuori dal resto della
/// dashboard ogni decisione specifica di CardStackSwiper.
class AmWorkshopSwiper extends StatelessWidget {
  final List<MechanicSummary> mechanics;
  final VoidCallback onAdd;
  final ValueChanged<MechanicSummary> onMechanicTap;

  const AmWorkshopSwiper({
    super.key,
    required this.mechanics,
    required this.onAdd,
    required this.onMechanicTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <MechanicSummary?>[null, ...mechanics];

    return SizedBox(
      height: 92,
      child: CardStackSwiper(
        cardsCount: items.length,
        initialIndex: 0,
        isLoop: items.length > 1,
        isDisabled: items.length == 1,
        maxAngle: 0,
        backCardAngle: 0,
        backCardScale: 0.97,
        backCardOffset: const Offset(10, -5),
        threshold: 22,
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
              ? const AmWorkshopCard.add()
              : AmWorkshopCard(mechanic: mechanic);
        },
      ),
    );
  }
}
