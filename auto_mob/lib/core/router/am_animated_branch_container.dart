import 'dart:async';

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// Espone lo scroll del pager ai gruppi Liquid Glass dei singoli branch.
class AmShellBranchRepaintScope extends InheritedWidget {
  const AmShellBranchRepaintScope({
    required this.repaint,
    required super.child,
    super.key,
  });

  final Listenable repaint;

  static Listenable? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AmShellBranchRepaintScope>()
      ?.repaint;

  @override
  bool updateShouldNotify(AmShellBranchRepaintScope oldWidget) =>
      repaint != oldWidget.repaint;
}

/// Mantiene vivi i Navigator dei branch e li sposta come pagine adiacenti.
///
/// Il vero [PageView] espone anche il proprio [ScrollPosition] ai discendenti:
/// OCLiquidGlass lo ascolta direttamente e aggiorna la geometria dello shader
/// mentre la pagina scorre, senza repaint manuali o gruppi glass duplicati.
class AmAnimatedBranchContainer extends StatefulWidget {
  const AmAnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AmAnimatedBranchContainer> createState() =>
      _AmAnimatedBranchContainerState();
}

class _AmAnimatedBranchContainerState extends State<AmAnimatedBranchContainer> {
  late final PageController _pageController;
  late final _PageGlassRepaintController _glassRepaint;
  late final List<_PageGlassRepaintProxy> _branchRepaints;
  late final ValueNotifier<bool> _isPageMoving;
  int _pageMotionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);
    _glassRepaint = _PageGlassRepaintController();
    _isPageMoving = ValueNotifier(false);
    _pageController.addListener(_glassRepaint.repaint);
    _branchRepaints = List.generate(
      widget.children.length,
      (_) => _PageGlassRepaintProxy(_glassRepaint),
    );
  }

  @override
  void didUpdateWidget(AmAnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    _rebindIncomingGlass(widget.currentIndex);
    _animateToCurrentPage();
  }

  void _rebindIncomingGlass(int index) {
    final previous = _branchRepaints[index];
    _branchRepaints[index] = _PageGlassRepaintProxy(_glassRepaint);
    // Il render object OCL deve prima ricevere la nuova identità Listenable;
    // il vecchio proxy viene sganciato soltanto dopo quell'update.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  void _animateToCurrentPage() {
    if (_pageController.hasClients) {
      final generation = ++_pageMotionGeneration;
      _isPageMoving.value = true;
      unawaited(
        _pageController
            .animateToPage(
              widget.currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
              if (!mounted || generation != _pageMotionGeneration) return;
              _isPageMoving.value = false;
              _glassRepaint.repaint();
            }),
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(widget.currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_glassRepaint.repaint);
    _pageController.dispose();
    for (final repaint in _branchRepaints) {
      repaint.dispose();
    }
    _isPageMoving.dispose();
    _glassRepaint.dispose();
    super.dispose();
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    if (notification.depth != 0) return false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _glassRepaint.repaint();
    });
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollEndNotification>(
        onNotification: _onScrollEnd,
        child: AmLiquidGlassMotionScope(
          isMoving: _isPageMoving,
          child: PageView(
            key: const Key('am-shell-page-view'),
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              widget.children.length,
              (index) => IgnorePointer(
                ignoring: index != widget.currentIndex,
                child: AmShellBranchRepaintScope(
                  repaint: _branchRepaints[index],
                  child: widget.children[index],
                ),
              ),
            ),
          ),
        ),
      );
}

class _PageGlassRepaintController extends ChangeNotifier {
  void repaint() => notifyListeners();
}

class _PageGlassRepaintProxy extends ChangeNotifier {
  _PageGlassRepaintProxy(this.source) {
    source.addListener(_forward);
  }

  final Listenable source;

  void _forward() => notifyListeners();

  @override
  void dispose() {
    source.removeListener(_forward);
    super.dispose();
  }
}
