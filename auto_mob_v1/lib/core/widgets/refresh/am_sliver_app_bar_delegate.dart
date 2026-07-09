import 'package:flutter/material.dart';

/// Adapter generico per mettere un contenuto ad altezza fissa dentro uno
/// `SliverPersistentHeader`. Usato per le app bar custom (liquid-glass) che
/// devono diventare sliver: con `pinned: true` restano fisse durante lo
/// scroll normale, ma vengono spinte giu' insieme a un
/// `CupertinoSliverRefreshControl` che le precede nella stessa lista di
/// sliver durante il pull-to-refresh.
class AmSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const AmSliverAppBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant AmSliverAppBarDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
