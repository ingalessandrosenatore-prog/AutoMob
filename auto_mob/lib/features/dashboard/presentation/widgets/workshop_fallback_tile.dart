import 'package:flutter/material.dart';
import '../../../vehicle/domain/entities/mechanic_summary.dart';

class WorkshopFallbackTile extends StatelessWidget {
  const WorkshopFallbackTile({
    super.key,
    required this.mechanic,
    required this.active,
    required this.scale,
    required this.top,
    required this.x,
    required this.onTap,
  });

  final MechanicSummary? mechanic;
  final bool active;
  final double scale;
  final double top;
  final double x;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: top,
      child: Transform.scale(
        scale: scale,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 110,
            height: 175,
            child: Column(
              children: [
                Container(
                  width: 94,
                  height: 136,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: active
                          ? const Color(0xFFFF7926)
                          : const Color(0xFF626268),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF373638), Color(0xFF101217)],
                    ),
                    boxShadow: active
                        ? [
                            const BoxShadow(
                              color: Color(0x77FF7926),
                              blurRadius: 16,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    mechanic == null
                        ? Icons.add_circle_outline
                        : Icons.engineering,
                    color: const Color(0xFFFF7926),
                    size: mechanic == null ? 44 : 57,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  mechanic?.businessName.toUpperCase() ?? 'Aggiungi officina',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFFB8B8BC),
                    fontSize: active ? 12 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
