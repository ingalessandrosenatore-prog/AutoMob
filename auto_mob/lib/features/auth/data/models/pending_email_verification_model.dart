class PendingEmailVerificationModel {
  const PendingEmailVerificationModel({
    required this.email,
    required this.lastSentAt,
  });

  final String email;
  final DateTime? lastSentAt;
}
