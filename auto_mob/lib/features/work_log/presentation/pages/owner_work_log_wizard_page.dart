import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../../../core/config/performance_flags.dart';

class OwnerWorkLogWizardPage extends StatelessWidget {
  const OwnerWorkLogWizardPage({
    required this.workLogContext,
    required this.cubit,
    super.key,
  });

  final WorkLogLaunchContext workLogContext;
  final WorkLogEditorCubit cubit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AmThemeColors.of(context).background,
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: 72,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: _OwnerBackButton(onPressed: () => context.pop(false)),
      ),
      title: Text(
        'AGGIUNGI LAVORO',
        style: TextStyle(
          color: AmThemeColors.of(context).textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    ),
    body: WorkLogWizardBody(
      context: workLogContext,
      cubit: cubit,
      onSaved: (_) => context.pop(true),
    ),
  );
}

class _OwnerBackButton extends StatelessWidget {
  const _OwnerBackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final button = AmSoftButton(
      width: 48,
      height: 48,
      color: colors.surface.withValues(alpha: 0.2),
      iconColor: colors.textPrimary,
      icon: HugeIcons.strokeRoundedArrowLeft01,
      onPressed: onPressed,
    );
    return kHeavyEffects
        ? OCLiquidGlassGroup(
            settings: const OCLiquidGlassSettings(
              refractStrength: -0.13,
              blurRadiusPx: 1,
              specStrength: 0,
              specWidth: 0,
              specAngle: 145,
              blendPx: 20,
              specPower: 10,
            ),
            child: button,
          )
        : button;
  }
}
