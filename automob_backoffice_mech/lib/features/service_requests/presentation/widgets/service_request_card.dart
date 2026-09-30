import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/mechanic_shapes.dart';
import '../../domain/entities/service_request.dart';

class ServiceRequestCard extends StatelessWidget {
  const ServiceRequestCard({
    required this.request,
    required this.onExecute,
    super.key,
  });
  final ServiceRequest request;
  final VoidCallback onExecute;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final shape = mechanicSmoothShape(radius: 24);
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: colors.cardBorderGradient,
        shape: shape,
        shadows: colors.cardShadows,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Material(
          color: colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: shape,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 42,
                      child: Center(
                        child: Container(
                          key: const ValueKey('request-timeline-start'),
                          width: 5,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.vehicleModel,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            request.plate.toUpperCase(),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (request.estimatedCost case final cost?) ...[
                      const SizedBox(width: 12),
                      _CostBadge(cost: cost),
                    ],
                  ],
                ),
                _TimelineConnector(color: colors.accent),
                ...request.issues.indexed.map(
                  (entry) => _IssueStep(
                    index: entry.$1,
                    issue: entry.$2,
                    continues: entry.$1 < request.issues.length - 1,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 190,
                    height: 50,
                    child: FilledButton(
                      key: ValueKey('execute-${request.id}'),
                      onPressed: onExecute,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.onMedia,
                        shape: mechanicSmoothShape(radius: 18),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Esegui'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      width: 12,
      height: 12,
      child: Center(
        child: Container(
          key: const ValueKey('request-timeline-connector'),
          width: 1.5,
          color: color.withValues(alpha: 0.72),
        ),
      ),
    ),
  );
}

class _IssueStep extends StatelessWidget {
  const _IssueStep({
    required this.index,
    required this.issue,
    required this.continues,
  });

  final int index;
  final String issue;
  final bool continues;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 12,
          height: 28,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 0,
                bottom: continues ? 0 : 14,
                child: Container(
                  width: 1.5,
                  color: colors.accent.withValues(alpha: 0.72),
                ),
              ),
              Positioned(
                top: 5,
                child: Container(
                  key: ValueKey('request-timeline-node-$index'),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              issue,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CostBadge extends StatelessWidget {
  const _CostBadge({required this.cost});
  final int cost;
  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.accentSecondary.withValues(alpha: 0.42),
        shape: mechanicSmoothShape(radius: 14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              '€ $cost',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'previsti',
              style: TextStyle(color: colors.textSecondary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
