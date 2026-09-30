import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// Header WorkLog con la stessa geometria dell'header della Home owner.
class WorkLogTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WorkLogTopAppBar({
    required this.leading,
    required this.title,
    required this.trailing,
    this.leadingWidth = 48,
    this.liquidGlassRepaint,
    this.liquidGlassGeneration,
    super.key,
  });

  static const contentHeight = 69.0;

  final Widget leading;
  final Widget title;
  final Widget trailing;
  final double? leadingWidth;
  final Listenable? liquidGlassRepaint;
  final Object? liquidGlassGeneration;

  @override
  Size get preferredSize => const Size.fromHeight(contentHeight);

  @override
  Widget build(BuildContext context) {
    Widget contentWith(Widget trailingChild) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              // Il Center interno dei controlli non deve espandersi nella colonna.
              child: SizedBox(width: leadingWidth, height: 48, child: leading),
            ),
          ),
          Expanded(child: Center(child: title)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: 48, height: 48, child: trailingChild),
            ),
          ),
        ],
      ),
    );
    final content = contentWith(trailing);
    final groupedContent = liquidGlassRepaint == null
        ? content
        : KeyedSubtree(
            // Se il branch viene riattivato, la nuova identità del repaint
            // forza OCL a registrare nuovamente forme e listener.
            key: ValueKey(liquidGlassGeneration ?? liquidGlassRepaint),
            child: OCLiquidGlassGroup(
              key: const Key('work-log-history-glass-group'),
              repaint: liquidGlassRepaint,
              settings: _workLogGlassSettings,
              child: content,
            ),
          );
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: groupedContent,
    );
  }
}

const _workLogGlassSettings = OCLiquidGlassSettings(
  refractStrength: -0.08,
  blurRadiusPx: 2,
  specStrength: 1,
  specWidth: 0.5,
  specAngle: 145,
  specPower: 10,
  lightbandOffsetPx: 7,
  lightbandStrength: 0.5,
);

/// Gruppo glass dedicato a un singolo controllo dell'AppBar.
///
/// I pull-down possiedono invece il gruppo internamente, così opacity e scale
/// trasformano insieme contenuto e superficie rifratta.
class WorkLogGlassControl extends StatelessWidget {
  const WorkLogGlassControl({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      OCLiquidGlassGroup(settings: _workLogGlassSettings, child: child);
}
