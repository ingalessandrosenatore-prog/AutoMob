import 'package:auto_mob_v1/core/widgets/buttons/soft_button.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/vehicle_option.dart';
import 'package:auto_mob_v1/features/work_log/presentation/pages/work_log_wizard_page.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

const _orange = Color(0xFFFF6B00);

/// Il pulsante `+` della pagina WorkLog che apre il wizard con una route
/// Material standard.
class WorkLogAddButton extends StatelessWidget {
  static const buttonKey = Key('work-log-add-button');

  final VehicleOption? vehicle;
  final VoidCallback onMissingVehicle;
  final VoidCallback onSaved;
  final WidgetBuilder? destinationBuilder;

  const WorkLogAddButton({
    super.key,
    required this.vehicle,
    required this.onMissingVehicle,
    required this.onSaved,
    this.destinationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final selected = vehicle;
    if (selected == null) {
      return _AddButton(onPressed: onMissingVehicle);
    }

    return _AddButton(onPressed: () => _openRegistration(context, selected));
  }

  Future<void> _openRegistration(
    BuildContext context,
    VehicleOption selected,
  ) async {
    final customDestination = destinationBuilder;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            customDestination ??
            (context) => WorkLogWizardPage(
              vehicleId: selected.id,
              currentKm: selected.km,
            ),
      ),
    );
    if (saved == true && context.mounted) onSaved();
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AmSoftButton(
      key: WorkLogAddButton.buttonKey,
      width: 45,
      height: 45,
      color: _orange,
      icon: HugeIcons.strokeRoundedAdd01,
      onPressed: onPressed,
    );
  }
}
