import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';

class AppAuthUserModel extends AppAuthUser {
  const AppAuthUserModel({required super.id, required super.email});

  factory AppAuthUserModel.fromSupabaseUser(User user) {
    return AppAuthUserModel(id: user.id, email: user.email ?? '');
  }
}
