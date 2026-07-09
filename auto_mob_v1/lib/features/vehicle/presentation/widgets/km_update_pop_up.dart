import 'package:auto_mob_v1/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/input/textfield.dart';
import '../bloc/km_update_cubit.dart';

/// Pop-up modale per l'aggiornamento dei chilometri del veicolo.
/// Implementato come PageRoute (Page) per l'integrazione con il router.
class KmUpdatePopUp<T> extends Page<T> {
  final String vehicleId;
  final String currentKm;

  const KmUpdatePopUp({
    super.key,
    required this.vehicleId,
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
      builder: (context) => BlocProvider<KmUpdateCubit>(
        create: (_) => sl<KmUpdateCubit>(),
        child: _KmUpdateContent(vehicleId: vehicleId, currentKm: currentKm),
      ),
      isScrollControlled: true,
    );
  }
}

class _KmUpdateContent extends StatefulWidget {
  final String vehicleId;
  final String currentKm;
  const _KmUpdateContent({required this.vehicleId, required this.currentKm});

  @override
  State<_KmUpdateContent> createState() => _KmUpdateContentState();
}

class _KmUpdateContentState extends State<_KmUpdateContent> {
  final _nuovoKmController = TextEditingController();

  /// km attuali del veicolo (parsati dalla stringa ricevuta).
  late final int _kmAttuali = int.tryParse(widget.currentKm) ?? 0;

  /// Messaggio di errore in tempo reale sotto il campo. Null = campo valido.
  String? _errore;

  /// Il nuovo km e' valido solo se e' un numero e supera i km attuali.
  bool get _valido {
    final n = int.tryParse(_nuovoKmController.text.trim());
    return n != null && n > _kmAttuali;
  }

  @override
  void dispose() {
    _nuovoKmController.dispose();
    super.dispose();
  }

  void _onChanged(dynamic _) {
    final testo = _nuovoKmController.text.trim();
    final n = int.tryParse(testo);
    setState(() {
      if (testo.isEmpty) {
        _errore = null; // niente errore finche' non si scrive
      } else if (n == null) {
        _errore = 'Inserisci un numero valido';
      } else if (n <= _kmAttuali) {
        _errore = 'Devono essere maggiori degli attuali ($_kmAttuali km)';
      } else {
        _errore = null;
      }
    });
  }

  void _salva() {
    if (!_valido) return;
    final nuovoKm = int.parse(_nuovoKmController.text.trim());
    context.read<KmUpdateCubit>().aggiorna(
          vehicleId: widget.vehicleId,
          newKm: nuovoKm,
        );
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFE85A1A);
    const Color darkContainerColor = Color(0xFF1C1C1E);

    return BlocConsumer<KmUpdateCubit, KmUpdateState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == KmUpdateStatus.success) {
          // Ritorno true al chiamante (HomeView) cosi' ricarica la dashboard.
          context.pop(true);
        } else if (state.status == KmUpdateStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Errore durante l\'aggiornamento'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == KmUpdateStatus.loading;
        final attivo = _valido && !loading;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          child: Container(
            color: const Color(0xFF0F0F11),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
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
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: darkContainerColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
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

                // Chilometraggio attuale (sempre visibile)
                const Text(
                  "Chilometraggio attuale   ",
                  style: TextStyle(
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
                      TextSpan(text: '$_kmAttuali'),
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

                // Campo nuovo chilometraggio (con validazione in tempo reale)
                Row(
                  children: [
                    AmTextField(
                      label: "NUOVO CHILOMETRAGGIO",
                      placeholder: "${_kmAttuali + 100}",
                      controller: _nuovoKmController,
                      isRequired: true,
                      obscureText: false,
                      keyboardType: TextInputType.number,
                      onChanged: _onChanged,
                      errorText: _errore,
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

                // Messaggio informativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: orangeColor, size: 20),
                      SizedBox(width: 12),
                      Expanded(
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

                // Bottone di azione (attivo solo se il nuovo km e' valido)
                GestureDetector(
                  onTap: attivo ? _salva : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: orangeColor.withValues(alpha: attivo ? 1.0 : 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            "Salva aggiornamento",
                            style: TextStyle(
                              color: attivo ? Colors.white : const Color(0xFF8E8E93),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
