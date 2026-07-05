import 'package:auto_mob_v1/core/widgets/buttons/soft_button.dart';
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

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(

            
            children: [
              // 1. Contenitore Icona (Sinistra)
              Expanded(child: Container()),
              // 2. Testi (Centro)
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 3. Pulsante X (Destra)
              Expanded(
                child: Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: AmSoftButton(
                    width: 45,
                    height: 45,
                    color: const Color(0xFFFF6B00),
                    icon: Icons.close,
                    onPressed: () {
                      onClose();
                    },
                  ),
                ),
              ),
            ],
          ),
         const SizedBox(height: 6,),
          // 4. Indicatore di progresso a pallini
          WizardProgressIndicator(
            currentStep: stepNumber,
            totalSteps: totalSteps,
            activeColor:  const Color(0xFFFF6B00),
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
