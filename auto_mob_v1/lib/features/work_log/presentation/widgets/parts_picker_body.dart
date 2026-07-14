import 'package:auto_mob_v1/core/constants/parts_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../bloc/work_log_bloc.dart';
import '../bloc/work_log_event.dart';
import '../bloc/work_log_state.dart';

/// CORPO del pannello: search bar fissa in cima + chip filtrabili.
///
/// PERFORMANCE — due mosse:
///  1. La ricerca riduce le chip mostrate (meno widget = meno lavoro).
///  2. Ogni chip usa BlocSelector -> si ricostruisce SOLO lei quando
///     cambia la SUA selezione, non tutte e 95.
class PartsPickerBody extends StatefulWidget {
  const PartsPickerBody({super.key});

  @override
  State<PartsPickerBody> createState() => _PartsPickerBodyState();
}

class _PartsPickerBodyState extends State<PartsPickerBody> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // filtro in memoria sulle entry del catalogo (unica fonte: kPartsCatalog)
    final entries = kPartsCatalog.entries.where((e) {
      if (_query.isEmpty) return true;
      return e.value.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Column(
      children: [
        // ── SEARCH BAR (primo elemento, FISSO, non scrolla) ───────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cerca pezzo...',
              hintStyle: const TextStyle(color: Color(0xFF636366)),
              prefixIcon: const HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: Color(0xFF636366),
                size: 18,
                strokeWidth: 2.2,
              ),
              filled: true,
              fillColor: const Color(0xFF151517),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // ── LISTA CHIP (scrolla; Wrap per larghezza variabile) ────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: entries
                  .map((e) => _ChipSelector(id: e.key, label: e.value))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Una chip che ascolta SOLO la propria selezione (rebuild localizzato).
class _ChipSelector extends StatelessWidget {
  final int id;
  final String label;
  const _ChipSelector({required this.id, required this.label});

  @override
  Widget build(BuildContext context) {
    // BlocSelector: ricostruisce SOLO quando cambia "sono io selezionato?".
    // Toccare un'altra chip NON ricostruisce questa.
    return BlocSelector<WorkLogBloc, WorkLogState, bool>(
      selector: (state) => state.selectedParts.any((p) => p.partId == id),
      builder: (context, isSelected) {
        return _AmChoiceChip(
          label: label,
          isSelected: isSelected,
          onTap: () => context.read<WorkLogBloc>().add(
            WorkLogEventCohiceTap(isSelected: isSelected, id: id),
          ),
        );
      },
    );
  }
}

/// La chip vera: press elastico a molla + cambio colore se selezionata.
class _AmChoiceChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _AmChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AmChoiceChip> createState() => _AmChoiceChipState();
}

class _AmChoiceChipState extends State<_AmChoiceChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  static final _spring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 300),
    bounce: 0.4,
  );

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _press() =>
      _scale.animateWith(SpringSimulation(_spring, _scale.value, 0.92, 0));
  void _release() =>
      _scale.animateWith(SpringSimulation(_spring, _scale.value, 1.0, 0));

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) {
        _release();
        widget.onTap();
      },
      onTapCancel: _release,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        // child fuori dal builder: non ricostruito ogni frame
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF0A84FF) : const Color(0xFF151517),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: sel ? const Color(0xFF0A84FF) : const Color(0xFF3A3A3C),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: sel ? Colors.white : const Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
