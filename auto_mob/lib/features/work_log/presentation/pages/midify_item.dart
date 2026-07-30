import 'package:auto_mob_v1/core/constants/parts_catalog.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/am_spare_part_card.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Midifyitem extends StatelessWidget {
  const Midifyitem({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkLogBloc, WorkLogState>(
      builder: (context, state) {
        if (state.selectedParts.isEmpty) {
          return const Center(
            child: Text(
              "Nessun pezzo selezionato",
              style: TextStyle(color: Color(0xFF636366), fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            top: 140,
            left: 20,
            right: 20,
            bottom: 100,
          ),
          itemCount: state.selectedParts.length,
          itemBuilder: (context, index) {
            final item = state.selectedParts[index];
            final name = kPartsCatalog[item.partId] ?? 'Sconosciuto';
            return AmSparePartCard(
              key: ValueKey(item.partId),
              item: item,
              name: name,
              onRemove: () => context.read<WorkLogBloc>().add(
                RemovePartEvent(partId: item.partId),
              ),
              onItemChanged: (updated) => context.read<WorkLogBloc>().add(
                UpdatePartItemEvent(item: updated),
              ),
            );
          },
        );
      },
    );
  }
}
