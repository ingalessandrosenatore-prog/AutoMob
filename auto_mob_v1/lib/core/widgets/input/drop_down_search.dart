import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<List<T>> _filteredNotifier = ValueNotifier([]);
  OverlayEntry? _overlayEntry;
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
    }
  }

  @override
  void dispose() {
    // Durante dispose `mounted` e' ancora true fino a super.dispose(): usare
    // _closeOverlay chiamerebbe quindi setState mentre l'elemento e' in fase
    // di smontaggio.
    _overlayEntry?.remove();
    _overlayEntry = null;
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

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

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
        triggerOffset: offset,
        triggerSize: size,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
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
          GestureDetector(
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
  final Offset triggerOffset;
  final Size triggerSize;

  static const double _itemHeight = 50.0;
  static const int _maxVisible = 5;

  const _DropdownOverlay({
    required this.filteredNotifier,
    required this.itemLabelBuilder,
    required this.selectedValue,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onDismiss,
    required this.triggerOffset,
    required this.triggerSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
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

        // Panel
        Positioned(
          left: triggerOffset.dx,
          top: triggerOffset.dy + triggerSize.height + 4,
          width: triggerSize.width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo cerca
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
                      autofocus: true,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cerca...',
                        hintStyle: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          color: colors.textSecondary,
                          size: 18,
                          strokeWidth: 2.2,
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

                  Container(height: 1, color: colors.border),

                  // Lista filtrata
                  ValueListenableBuilder<List<T>>(
                    valueListenable: filteredNotifier,
                    builder: (context, items, _) {
                      if (items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
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

                      return ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _itemHeight * _maxVisible,
                        ),
                        child: ListView.builder(
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
                                child: Row(
                                  children: [
                                    Expanded(
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
                                    if (isSelected)
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedValidation,
                                        color: colors.accent,
                                        size: 16,
                                        strokeWidth: 2.2,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
