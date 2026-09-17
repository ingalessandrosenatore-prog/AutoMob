import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/mechanic_notification.dart';

abstract interface class MechanicNotificationDataSource {
  Future<NotificationSendResult> send(MechanicNotification notification);
}

final class SupabaseMechanicNotificationDataSource
    implements MechanicNotificationDataSource {
  const SupabaseMechanicNotificationDataSource(this.client);
  final SupabaseClient client;

  @override
  Future<NotificationSendResult> send(MechanicNotification notification) async {
    final response = await client.functions.invoke(
      'send-mechanic-notification',
      body: {
        'vehicle_id': notification.vehicleId,
        'request_id': notification.requestId,
        'intervention_type': notification.type.code,
        'title': notification.title,
        'body': notification.body,
      },
    );
    final data = response.data;
    if (response.status != 200 || data is! Map) {
      throw const FormatException('Invalid notification response');
    }
    return switch (data['status']) {
      'sent' => NotificationSendResult.sent,
      'pending' => NotificationSendResult.pending,
      'no_device' => NotificationSendResult.noDevice,
      'failed' => NotificationSendResult.failed,
      _ => throw const FormatException('Unknown notification status'),
    };
  }
}
