import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_auth_user.dart';

final class AppAuthUserModel extends AppAuthUser {
  const AppAuthUserModel({required super.id, required super.email});

  factory AppAuthUserModel.fromSupabase(User user) =>
      AppAuthUserModel(id: user.id, email: user.email ?? '');
}
