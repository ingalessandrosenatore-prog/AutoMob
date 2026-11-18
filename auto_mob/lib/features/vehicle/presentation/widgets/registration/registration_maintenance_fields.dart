import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/input/date_picker_field.dart';
import '../../../domain/entities/vehicle_draft.dart';
import '../../../domain/entities/vehicle_maintenance_setting.dart';
import '../maintenance_section_card.dart';
import 'maintenance_interval_field.dart';

class RegistrationMaintenanceFields {
  static const tagliando = [
    VehicleMaintenanceField.oil,
    VehicleMaintenanceField.air,
    VehicleMaintenanceField.cabin,
    VehicleMaintenanceField.fuel,
  ];

  final _intervals = {
    for (final field in VehicleMaintenanceField.values)
      field: TextEditingController(),
  };
  final _last = {
    for (final field in VehicleMaintenanceField.values)
      if (field.separateReference || field.optional || field.years != null)
        field: TextEditingController(),
  };
  final brakeInspection = TextEditingController();
  final _configuredOptionalIntervals = <VehicleMaintenanceField>{};

  void markIntervalEdited(VehicleMaintenanceField field) {
    if (field.optional) _configuredOptionalIntervals.add(field);
  }

  TextEditingController interval(VehicleMaintenanceField field) =>
      _intervals[field]!;
  TextEditingController? last(VehicleMaintenanceField field) => _last[field];

  void load(VehicleDraft draft) {
    _configuredOptionalIntervals
      ..clear()
      ..addAll(
        draft.maintenanceSettings
            .map((setting) => setting.field)
            .where((field) => field.optional),
      );
    final saved = {
      for (final setting in draft.maintenanceSettings) setting.field: setting,
    };
    for (final field in VehicleMaintenanceField.values) {
      final configured = saved[field];
      final intervalValue =
          configured?.intervalKm ??
          configured?.intervalYears ??
          (field == VehicleMaintenanceField.oil
              ? draft.intervalloUltimoTagliando
              : null) ??
          field.km ??
          field.years;
      interval(field).text = intervalValue?.toString() ?? '';
      last(field)?.text = field.years != null
          ? dateText(configured?.lastDate)
          : configured?.lastKm?.toString() ?? '';
    }
    brakeInspection.text = dateText(draft.brakeInspectionDate);
  }

  List<VehicleMaintenanceSetting> read({
    required String? fuel,
    required int? tagliandoKm,
  }) {
    final settings = <VehicleMaintenanceSetting>[];
    for (final field in VehicleMaintenanceField.values.where(
      (field) => field.appliesTo(fuel),
    )) {
      if (field == VehicleMaintenanceField.distribution ||
          field == VehicleMaintenanceField.tires) {
        continue;
      }
      final yearsOnly = field.km == null;
      final selected = MaintenanceIntervalField.read(
        interval(field),
        years: yearsOnly,
      );
      final lastText = last(field)?.text ?? '';
      final lastKm = tagliando.contains(field)
          ? tagliandoKm
          : int.tryParse(lastText);
      final lastDate = field.years == null ? null : parseDate(lastText);
      if (field.optional &&
          lastKm == null &&
          lastDate == null &&
          (selected == null ||
              selected == 0 ||
              !_configuredOptionalIntervals.contains(field))) {
        continue;
      }
      settings.add(
        VehicleMaintenanceSetting(
          field: field,
          intervalKm: yearsOnly
              ? null
              : (selected == null || selected == 0 ? field.km : selected),
          intervalYears: yearsOnly ? selected ?? field.years : field.years,
          lastKm: lastKm,
          lastDate: lastDate,
        ),
      );
    }
    return List.unmodifiable(settings);
  }

  void dispose() {
    for (final controller in [
      ..._intervals.values,
      ..._last.values,
      brakeInspection,
    ]) {
      controller.dispose();
    }
  }

  static String dateText(DateTime? value) => value == null
      ? ''
      : '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static DateTime? parseDate(String text) {
    final parts = text.split('/').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((part) => part == null)) return null;
    return DateTime(parts[2]!, parts[1]!, parts[0]!);
  }
}

class RegistrationMaintenanceField extends StatelessWidget {
  const RegistrationMaintenanceField({
    super.key,
    required this.field,
    required this.fields,
  });

  final VehicleMaintenanceField field;
  final RegistrationMaintenanceFields fields;

  @override
  Widget build(BuildContext context) {
    final reference = fields.last(field);
    final yearsOnly = field.km == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reference != null && field.years != null)
          Row(
            children: [
              AmDatePickerField(
                label: field == VehicleMaintenanceField.oil
                    ? 'Data ultimo tagliando'
                    : 'Data ultimo intervento',
                placeholder: 'gg/mm/aaaa',
                controller: reference,
                lastDate: DateTime.now(),
                height: 52,
              ),
            ],
          ),
        if (reference != null && field.years == null)
          Row(
            children: [
              AmTextField(
                label: 'Ultimo intervento · ${field.label}',
                placeholder: 'km',
                controller: reference,
                isRequired: false,
                obscureText: false,
                keyboardType: TextInputType.number,
                height: 52,
              ),
            ],
          ),
        if (reference != null) const SizedBox(height: 8),
        MaintenanceIntervalField(
          controller: fields.interval(field),
          label: field.label,
          years: yearsOnly,
          onEdited: () => fields.markIntervalEdited(field),
        ),
      ],
    );
  }
}

class RegistrationAdditionalMaintenance extends StatelessWidget {
  const RegistrationAdditionalMaintenance({
    super.key,
    required this.fields,
    required this.fuel,
  });

  final RegistrationMaintenanceFields fields;
  final String? fuel;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final groups = [
      (
        title: 'Freni',
        icon: Icons.car_repair,
        items: [
          VehicleMaintenanceField.pads,
          VehicleMaintenanceField.brakeFluid,
        ],
      ),
      (
        title: 'Motore',
        icon: Icons.build_outlined,
        items: [VehicleMaintenanceField.sparkPlugs],
      ),
      (
        title: 'Trasmissione',
        icon: Icons.settings_outlined,
        items: [
          VehicleMaintenanceField.gearbox,
          VehicleMaintenanceField.differential,
        ],
      ),
      if (VehicleMaintenanceField.lpgTank.appliesTo(fuel))
        (
          title: 'GPL',
          icon: Icons.local_gas_station_outlined,
          items: [
            VehicleMaintenanceField.lpgFilter,
            VehicleMaintenanceField.lpgTank,
          ],
        ),
      if (VehicleMaintenanceField.cngTank.appliesTo(fuel))
        (
          title: 'Metano',
          icon: Icons.local_gas_station_outlined,
          items: [VehicleMaintenanceField.cngTank],
        ),
    ];

    return Column(
      children: [
        for (final group in groups) ...[
          const SizedBox(height: 20),
          MaintenanceSectionCard(
            title: group.title,
            uppercaseTitle: true,
            icon: group.icon,
            iconColor: colors.accent,
            children: [
              if (group.items.contains(VehicleMaintenanceField.pads)) ...[
                Row(
                  children: [
                    AmDatePickerField(
                      label: 'Ultimo controllo freni',
                      placeholder: 'gg/mm/aaaa',
                      controller: fields.brakeInspection,
                      lastDate: DateTime.now(),
                      height: 52,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              for (final field in group.items) ...[
                if (field == VehicleMaintenanceField.differential)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Facoltativo · solo 4×4 o trazione posteriore'),
                  ),
                if (field == VehicleMaintenanceField.gearbox)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Manuale 80.000 km · automatico 100.000 km'),
                  ),
                RegistrationMaintenanceField(field: field, fields: fields),
                if (field != group.items.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
