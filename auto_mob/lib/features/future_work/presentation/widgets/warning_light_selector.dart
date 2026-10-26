import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/future_work_report_cubit.dart';
import 'warning_light_choice.dart';

class WarningLightSelector extends StatelessWidget {
  const WarningLightSelector({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FutureWorkReportCubit, FutureWorkReportState>(
    builder: (context, state) {
      final cubit = context.read<FutureWorkReportCubit>();
      final enabled = state.status != FutureWorkReportStatus.submitting;
      // Grow square tiles with text scaling while keeping exactly two rows.
      final tileExtent =
          120.0 +
          (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 24) * 4;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quali spie hai visto?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Seleziona le spie come le hai viste: colore, fisse o lampeggianti.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: tileExtent * 2 + 10,
            child: GridView.builder(
              key: const ValueKey('warning-light-grid'),
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: tileExtent,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: amSelectableWarningLights.length,
              itemBuilder: (context, index) {
                final option = amSelectableWarningLights[index];
                final selected = state.warningLights
                    .where(
                      (light) =>
                          light.code == option.code &&
                          light.color == option.color &&
                          light.flashing == option.flashing,
                    )
                    .firstOrNull;
                final light = AmWarningLightData(
                  code: option.code,
                  color: option.color,
                  flashing: option.flashing,
                );
                return WarningLightChoice(
                  key: ValueKey(
                    'warning-choice-${option.code}-${option.color}-${option.flashing}',
                  ),
                  light: light,
                  selected: selected != null,
                  onSelected: enabled
                      ? () => cubit.toggleWarning(
                          option.code,
                          color: option.color,
                          flashing: option.flashing,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
