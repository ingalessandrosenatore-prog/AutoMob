import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/subscription_overview_model.dart';

abstract interface class SubscriptionDataSource {
  Future<SubscriptionOverviewModel> getOverview();
}

final class SupabaseSubscriptionDataSource implements SubscriptionDataSource {
  const SupabaseSubscriptionDataSource(this.client);

  final SupabaseClient client;

  @override
  Future<SubscriptionOverviewModel> getOverview() async {
    try {
      final response = await client.rpc('get_mechanic_subscription_overview');
      if (response is! Map) {
        throw const FormatException('Profilo meccanico non disponibile');
      }
      return SubscriptionOverviewModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } on SocketException {
      rethrow;
    } on PostgrestException {
      rethrow;
    }
  }
}
