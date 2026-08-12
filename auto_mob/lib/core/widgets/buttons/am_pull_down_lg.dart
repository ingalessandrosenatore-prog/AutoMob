import 'package:auto_mob_v1/core/config/performance_flags.dart';
import 'package:common_ui_widget/common_ui_widget.dart' as shared;

export 'package:common_ui_widget/common_ui_widget.dart'
    show ItemMorphPopUp, MorphPopUp;

/// Compatibilita temporanea per i chiamanti owner ancora sul vecchio path.
/// Il widget reale vive in common_ui_widget ed e condiviso con WorkLog.
class AmPullDownLG extends shared.AmPullDownLG {
  const AmPullDownLG({
    required super.brand,
    required super.lable,
    required super.backgroundColor,
    required super.popupBackgroundColor,
    required super.onTap,
    required super.children,
    required super.buttonIcons,
    required super.buttonIconsSize,
    required super.iconColor,
    required super.textColor,
    required super.buttonLableStyle,
    required super.arrow,
    super.key,
    super.larghezza = 250.0,
    super.liquidGlassEnabled = kHeavyEffects,
  });
}
