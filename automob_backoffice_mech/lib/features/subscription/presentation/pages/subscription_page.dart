import 'dart:async';

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_route_names.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';
import '../widgets/subscription_overview_view.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  void _copyMechanicCode(BuildContext context, String code) {
    unawaited(Clipboard.setData(ClipboardData(text: code)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Codice officina copiato'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) => switch (state) {
          SubscriptionReady ready => SubscriptionOverviewView(
            overview: ready.overview,
            onRefresh: () => context.read<SubscriptionBloc>().add(
              const SubscriptionRetryRequested(),
            ),
            onCopyCode: () =>
                _copyMechanicCode(context, ready.overview.mechanicCode),
            onPlanPressed: () => context.pushNamed(
              AppRouteNames.subscriptionPlan,
              extra: ready.overview,
            ),
            onProfilePressed: () =>
                context.pushNamed(AppRouteNames.workshopProfile),
          ),
          SubscriptionLoadFailure failure => _SubscriptionFailure(
            message: failure.message,
            onRetry: () => context.read<SubscriptionBloc>().add(
              const SubscriptionRetryRequested(),
            ),
          ),
          SubscriptionInitial() ||
          SubscriptionLoading() => const _SubscriptionLoading(),
        },
      );
}

class _SubscriptionLoading extends StatelessWidget {
  const _SubscriptionLoading();

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SubscriptionFailure extends StatelessWidget {
  const _SubscriptionFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: colors.danger, size: 42),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textPrimary, fontSize: 15),
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: onRetry, child: const Text('Riprova')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
