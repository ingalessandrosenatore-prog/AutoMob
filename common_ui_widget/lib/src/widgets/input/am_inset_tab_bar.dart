import 'package:flutter/material.dart';

import '../../theme/am_theme_colors.dart';

/// Controlled segmented selector. Selection and content belong to the caller.
class AmInsetTabBar extends StatelessWidget {
  const AmInsetTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.compact = false,
  }) : assert(labels.length > 1),
       assert(selectedIndex >= 0 && selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isLight ? colors.border : colors.shadow,
            colors.borderHighlight,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: DecoratedBox(
            // The clipped gradient casts the recess inside the upper edge.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isLight ? colors.surfaceDeep : colors.shadow,
                  colors.surfaceDeep,
                  colors.surface,
                ],
                stops: const [0, 0.35, 1],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 3 : 5,
                vertical: compact ? 6 : 5,
              ),
              child: Row(
                children: List.generate(labels.length, (index) {
                  final selected = index == selectedIndex;
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      child: AnimatedContainer(
                        margin: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 0,
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: selected ? colors.cardGradient : null,
                          border: Border.all(
                            color: selected && isLight
                                ? colors.borderHighlight
                                : Colors.transparent,
                          ),
                          boxShadow: selected ? colors.cardShadows : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: () => onChanged(index),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: compact ? 42 : 48,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: compact ? 8 : 10,
                                ),
                                child: Center(
                                  child: Text(
                                    labels[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? colors.accent
                                          : colors.textSecondary,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
