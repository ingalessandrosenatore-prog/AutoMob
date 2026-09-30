import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/router/mechanic_shell_metrics.dart';
import '../../domain/entities/subscription_overview.dart';
import 'subscription_cards.dart';
import 'subscription_top_app_bar.dart';

class SubscriptionOverviewView extends StatelessWidget {
  const SubscriptionOverviewView({
    super.key,
    required this.overview,
    required this.onRefresh,
    required this.onCopyCode,
    required this.onPlanPressed,
    required this.onProfilePressed,
  });

  static const _wideLayoutBreakpoint = 620.0;
  static const _appBarHeight = 80.0;

  final SubscriptionOverview overview;
  final VoidCallback onRefresh;
  final VoidCallback onCopyCode;
  final VoidCallback onPlanPressed;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final appBarExtent = topInset + _appBarHeight;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: colors.background,
                  child: SoftEdgeBlur(
                    key: const ValueKey('subscription_soft_edge_blur'),
                    edges: [
                      EdgeBlur(
                        type: EdgeType.topEdge,
                        size: 150,
                        tintColor: colors.background,
                        sigma: 10,
                        controlPoints: [
                          ControlPoint(
                            position: 0.45,
                            type: ControlPointType.visible,
                          ),
                          ControlPoint(
                            position: 1,
                            type: ControlPointType.transparent,
                          ),
                        ],
                      ),
                      EdgeBlur(
                        type: EdgeType.bottomEdge,
                        size: 135,
                        tintColor: colors.background,
                        sigma: 10,
                        controlPoints: [
                          ControlPoint(
                            position: 0.45,
                            type: ControlPointType.visible,
                          ),
                          ControlPoint(
                            position: 1,
                            type: ControlPointType.transparent,
                          ),
                        ],
                      ),
                    ],
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide =
                            constraints.maxWidth >= _wideLayoutBreakpoint;
                        return SingleChildScrollView(
                          key: const ValueKey('subscription_scroll_view'),
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            appBarExtent + 20,
                            24,
                            MechanicShellMetrics.navigationHeight + 68,
                          ),
                          child: _SubscriptionContent(
                            overview: overview,
                            wide: wide,
                            onCopyCode: onCopyCode,
                            onPlanPressed: onPlanPressed,
                            onProfilePressed: onProfilePressed,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const ValueKey('subscription_app_bar'),
                top: 0,
                left: 0,
                right: 0,
                height: appBarExtent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.background,
                        colors.background.withValues(alpha: 0.82),
                        colors.background.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.78, 1],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, topInset, 20, 0),
                    child: SizedBox(
                      height: _appBarHeight,
                      child: SubscriptionTopAppBar(onRefresh: onRefresh),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionContent extends StatelessWidget {
  const _SubscriptionContent({
    required this.overview,
    required this.wide,
    required this.onCopyCode,
    required this.onPlanPressed,
    required this.onProfilePressed,
  });

  final SubscriptionOverview overview;
  final bool wide;
  final VoidCallback onCopyCode;
  final VoidCallback onPlanPressed;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SubscriptionPlanCard(overview: overview, onPressed: onPlanPressed),
      const SizedBox(height: 14),
      if (wide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MechanicCodeCard(
                code: overview.mechanicCode,
                onCopy: onCopyCode,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: VehicleUsageCard(overview: overview)),
          ],
        )
      else ...[
        MechanicCodeCard(code: overview.mechanicCode, onCopy: onCopyCode),
        const SizedBox(height: 14),
        VehicleUsageCard(overview: overview),
      ],
      const SizedBox(height: 14),
      WorkshopSummaryCard(
        workshopName: overview.workshopName,
        onPressed: onProfilePressed,
      ),
    ],
  );
}
