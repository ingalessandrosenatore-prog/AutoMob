import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

class WorkshopEmptyState extends StatelessWidget {
  const WorkshopEmptyState({super.key});

  @override
  Widget build(BuildContext context) => const WorkshopMessagePlaceholder(
    icon: Icons.directions_car_filled_rounded,
    title: 'Non hai veicoli collegati alla tua officina',
    message: 'Invita i clienti inserendo il tuo codice officina.',
  );
}

class WorkshopNoSearchResults extends StatelessWidget {
  const WorkshopNoSearchResults({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => WorkshopMessagePlaceholder(
    icon: Icons.search_off_rounded,
    title: 'Nessun veicolo trovato',
    message: 'Nessun risultato per “$query”. Prova con marca, modello o targa.',
  );
}

/// Empty and no-results states share the same visual hierarchy; only their
/// icon and copy differ, so the spacing and typography cannot drift apart.
class WorkshopMessagePlaceholder extends StatelessWidget {
  const WorkshopMessagePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.18),
                    blurRadius: 36,
                  ),
                ],
              ),
              child: Icon(icon, size: 54, color: colors.accent),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkshopLoadFailurePlaceholder extends StatelessWidget {
  const WorkshopLoadFailurePlaceholder({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(onPressed: onRetry, child: const Text('Riprova')),
  );
}
