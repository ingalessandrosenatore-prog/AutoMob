import 'package:flutter/material.dart';

/// Header per i Wizard dell'app AutoMob.
/// Segue le specifiche: icona a sinistra, titolo centrale, pulsante chiusura a destra
/// e indicatore di progresso a pallini in basso.
class WizardHeader extends StatelessWidget {
  final IconData stepIcon;
  final int stepNumber;
  final int totalSteps;
  final String title;
  final VoidCallback onClose;

  const WizardHeader({
    super.key,
    required this.stepIcon,
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFE85A1A);
    const Color darkContainerColor = Color(0xFF1C1C1E);
    const Color iconContainerColor = Color(0xFF2C2C2E);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Contenitore Icona (Sinistra)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: darkContainerColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),

                ),
                child: Icon(
                  stepIcon,
                  color: orangeColor,
                  size: 24,
                  shadows: [
                    Shadow(
                      color: orangeColor.withOpacity(0.8),
                      blurRadius: 50,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 2. Testi (Centro)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP $stepNumber DI $totalSteps',
                      style: const TextStyle(
                        color: orangeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // 3. Pulsante X (Destra)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: darkContainerColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: orangeColor.withOpacity(0.3),
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: orangeColor.withOpacity(0.3),
                        blurRadius: 25,

                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: orangeColor,

                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 4. Indicatore di progresso a pallini
          WizardProgressIndicator(
            currentStep: stepNumber,
            totalSteps: totalSteps,
            activeColor: orangeColor,
          ),
        ],
      ),
    );
  }
}

/// Widget interno per i pallini di progresso.
/// Creato come classe separata per rispettare la regola "no funzioni che ritornano widget".
class WizardProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;

  const WizardProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final bool isActive = (index + 1) <= currentStep;
        final bool isCurrent = (index + 1) == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          // Se è lo step corrente, lo rendiamo una pillola lunga
          width: isCurrent ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}