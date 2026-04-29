import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/Exception/Exceptions.dart';
import '../models/vehicle_draft_model.dart';

abstract class VehicleDraftLocalDataSource {
  /// Salva il draft in SharedPreferences. Lancia [CacheException] in caso di errore.
  Future<void> saveDraft(VehicleDraftModel draft);
}

class VehicleDraftLocalDataSourceImpl implements VehicleDraftLocalDataSource {
  static const _draftKey = 'vehicle_draft';

  final SharedPreferences prefs;

  VehicleDraftLocalDataSourceImpl(this.prefs);

  @override
  Future<void> saveDraft(VehicleDraftModel draft) async {
    try {
      final json = jsonEncode(draft.toJson());
      final ok = await prefs.setString(_draftKey, json);
      if (!ok) {
        throw const CacheException('Salvataggio draft fallito');
      }
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException('Errore salvataggio draft: $e');
    }
  }
}
