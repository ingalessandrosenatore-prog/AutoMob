import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/input/Textfield.dart';

/// Pop-up modale per l'aggiornamento dei chilometri del veicolo.
/// Implementato come PageRoute (Page) per l'integrazione con il router.
class KmUpdatePopUp<T> extends Page<T> {
  final String currentKm;

  const KmUpdatePopUp({
    super.key,
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
      builder: (context) =>  _KmUpdateContent(currentKm: currentKm),
      isScrollControlled: true,
    );
  }
}

class _KmUpdateContent extends StatelessWidget {
  final String currentKm;
  const _KmUpdateContent({required this.currentKm});

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFE85A1A);
    const Color darkContainerColor = Color(0xFF1C1C1E);
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: const Color(0xFF0F0F11).withOpacity(0.95),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header personalizzato per matchare la foto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Aggiorna chilometri",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop('/home'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: darkContainerColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4A90E2).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF4A90E2),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Chilometraggio Attuale
               const Text(
                "Chilometraggio attuale   ",
                style: const TextStyle(
                  color: Color(0xFF636366),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: orangeColor,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(text: currentKm),
                    const TextSpan(
                      text: " km",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Campo Nuovo Chilometraggio
              Row(
                children: [
                  AmTextField(
                    label: "NUOVO CHILOMETRAGGIO",
                    placeholder: "45230",
                    controller: TextEditingController(),
                    isRequired: false,
                    obscureText: false,
                    keyboardType: TextInputType.number,
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 16, top: 18),
                      child: Text(
                        "km",
                        style: TextStyle(
                          color: Color(0xFF48484A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Messaggio Informativo (Il meccanico...)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: orangeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Il meccanico collegato riceverà una notifica dell'aggiornamento.",
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Bottone di Azione
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE85A1A).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Salva aggiornamento",
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
