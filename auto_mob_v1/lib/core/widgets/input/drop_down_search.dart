import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../config/performance_flags.dart';
import '../../theme/am_theme_colors.dart';

class AmDropdownSearch<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final String placeholder;
  final bool isRequired;
  final double height;

  const AmDropdownSearch({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.value,
    required this.placeholder,
    this.isRequired = true,
    this.height = 60,
  });

  @override
  State<AmDropdownSearch<T>> createState() => _AmDropdownSearchState<T>();
}

class _AmDropdownSearchState<T> extends State<AmDropdownSearch<T>> {
  final GlobalKey _triggerKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<List<T>> _filteredNotifier = ValueNotifier([]);
  OverlayEntry? _overlayEntry;
  ScrollPosition? _scrollPosition;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredNotifier.value = widget.items;
  }

  @override
  void didUpdateWidget(AmDropdownSearch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredNotifier.value = widget.items;
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    // Durante dispose `mounted` e' ancora true fino a super.dispose(): usare
    // _closeOverlay chiamerebbe quindi setState mentre l'elemento e' in fase
    // di smontaggio.
    _overlayEntry?.remove();
    _overlayEntry = null;
    _detachScrollListener();
    _isOpen = false;
    _searchCtrl.dispose();
    _filteredNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _filteredNotifier.value = query.isEmpty
        ? widget.items
        : widget.items
              .where(
                (item) => widget
                    .itemLabelBuilder(item)
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
    _overlayEntry?.markNeedsBuild();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _searchCtrl.clear();
    _filteredNotifier.value = widget.items;

    _overlayEntry = OverlayEntry(
      builder: (_) => _DropdownOverlay<T>(
        filteredNotifier: _filteredNotifier,
        itemLabelBuilder: widget.itemLabelBuilder,
        selectedValue: widget.value,
        searchCtrl: _searchCtrl,
        onSearchChanged: _onSearchChanged,
        onSelect: (item) {
          widget.onChanged(item);
          _closeOverlay();
        },
        onDismiss: _closeOverlay,
        layerLink: _layerLink,
        triggerKey: _triggerKey,
      ),
    );

    _attachScrollListener();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _detachScrollListener();
    if (mounted) setState(() => _isOpen = false);
  }

  void _attachScrollListener() {
    _detachScrollListener();
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_refreshOverlayLayout);
  }

  void _detachScrollListener() {
    _scrollPosition?.removeListener(_refreshOverlayLayout);
    _scrollPosition = null;
  }

  void _refreshOverlayLayout() {
    _overlayEntry?.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final selectedLabel = widget.value != null
        ? widget.itemLabelBuilder(widget.value as T)
        : null;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(text: widget.label.toUpperCase()),
                if (widget.isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colors.info),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CompositedTransformTarget(
            key: const ValueKey('am-dropdown-search-target'),
            link: _layerLink,
            child: GestureDetector(
              key: _triggerKey,
              onTap: _toggleOverlay,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isOpen
                        ? colors.accent.withValues(alpha: 0.5)
                        : colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel ?? widget.placeholder,
                        style: TextStyle(
                          color: selectedLabel != null
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        color: colors.textSecondary,
                        size: 22,
                        strokeWidth: 2.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownOverlay<T> extends StatelessWidget {
  final ValueNotifier<List<T>> filteredNotifier;
  final String Function(T) itemLabelBuilder;
  final T? selectedValue;
  final TextEditingController searchCtrl;
  final void Function(String) onSearchChanged;
  final void Function(T) onSelect;
  final VoidCallback onDismiss;
  final LayerLink layerLink;
  final GlobalKey triggerKey;

  static const double _itemHeight = 50.0;
  static const int _maxVisible = 5;
  static const double _gap = 4.0;
  static const double _viewportMargin = 8.0;
  static const double _searchInputHeight = 38.0;
  static const double _searchAreaHeight = _searchInputHeight + 21.0;
  static const double _emptyResultsHeight = 60.0;
  static const double _bottomSpacing = 4.0;

  const _DropdownOverlay({
    required this.filteredNotifier,
    required this.itemLabelBuilder,
    required this.selectedValue,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onDismiss,
    required this.layerLink,
    required this.triggerKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final triggerBox =
        triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (triggerBox == null || !triggerBox.hasSize) {
      return const SizedBox.shrink();
    }

    final triggerOffset = triggerBox.localToGlobal(Offset.zero);
    final triggerSize = triggerBox.size;
    final mediaQuery = MediaQuery.of(context);
    final usableTop = mediaQuery.padding.top + _viewportMargin;
    final usableBottom =
        mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.padding.bottom -
        _viewportMargin;
    final triggerTop = triggerOffset.dy;
    final triggerBottom = triggerTop + triggerSize.height;
    final spaceAbove = (triggerTop - usableTop - _gap).clamp(
      0.0,
      double.infinity,
    );
    final spaceBelow = (usableBottom - triggerBottom - _gap).clamp(
      0.0,
      double.infinity,
    );
    final visibleItems = filteredNotifier.value.length.clamp(0, _maxVisible);
    final resultsHeight = filteredNotifier.value.isEmpty
        ? _emptyResultsHeight
        : visibleItems * _itemHeight + 8;
    final desiredHeight = _searchAreaHeight + resultsHeight + _bottomSpacing;
    final openBelow =
        spaceBelow >= desiredHeight ||
        (spaceAbove < desiredHeight && spaceBelow >= spaceAbove);
    final availableHeight = openBelow ? spaceBelow : spaceAbove;
    final panelMaxHeight = desiredHeight.clamp(0.0, availableHeight).toDouble();

    return Stack(
      children: [
        // Barrier — tap fuori chiude
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        // Il follower resta agganciato al campo anche quando la pagina scorre.
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: openBelow ? Alignment.bottomLeft : Alignment.topLeft,
          followerAnchor: openBelow ? Alignment.topLeft : Alignment.bottomLeft,
          offset: Offset(0, openBelow ? _gap : -_gap),
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              key: const ValueKey('am-dropdown-search-panel'),
              width: triggerSize.width,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: panelMaxHeight),
                child: _DropdownSurface(
                  color: colors.surfaceRaised,
                  borderColor: colors.border,
                  shadowColor: colors.shadow,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Campo cerca
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: SizedBox(
                          height: _searchInputHeight,
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: onSearchChanged,
                            autofocus: true,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cerca...',
                              hintStyle: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                              prefixIcon: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedSearch01,
                                  color: colors.textSecondary,
                                  size: 16,
                                  strokeWidth: 2.2,
                                ),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints.tightFor(
                                    width: 38,
                                    height: _searchInputHeight,
                                  ),
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),

                      Container(height: 1, color: colors.border),

                      // Lista filtrata
                      Flexible(
                        child: ValueListenableBuilder<List<T>>(
                          valueListenable: filteredNotifier,
                          builder: (context, items, _) {
                            if (items.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    'Nessun risultato',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: items.length,
                              itemExtent: _itemHeight,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final isSelected = item == selectedValue;

                                return InkWell(
                                  onTap: () => onSelect(item),
                                  borderRadius: BorderRadius.circular(8),
                                  highlightColor: colors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  splashColor: colors.accent.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: Container(
                                    height: _itemHeight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      itemLabelBuilder(item),
                                      style: TextStyle(
                                        color: isSelected
                                            ? colors.accent
                                            : colors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Superficie pesante sui device abilitati, fallback solido sugli altri.
class _DropdownSurface extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final Widget child;

  const _DropdownSurface({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 16.0;
    final shadow = BoxShadow(
      color: shadowColor.withValues(alpha: 0.45),
      blurRadius: 24,
      offset: const Offset(0, 8),
    );

    if (!kHeavyEffects) {
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
          boxShadow: [shadow],
        ),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [shadow],
      ),
      child: OCLiquidGlassGroup(
        settings: const OCLiquidGlassSettings(
          blurRadiusPx: 5,
          refractStrength: -0.10,
          specStrength: 0,
          specWidth: 0,
        ),
        child: OCLiquidGlass(
          enabled: true,
          borderRadius: radius,
          color: color.withValues(alpha: 0.8),
          child: child,
        ),
      ),
    );
  }
}
