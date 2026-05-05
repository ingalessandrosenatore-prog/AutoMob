import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/Exception/Exceptions.dart';
import '../models/vehicle_draft_model.dart';

abstract class VehicleDraftLocalDataSource {
  /// Salva il draft in SharedPreferences. Lancia [CacheException] in caso di errore.
  Future<void> saveDraft(VehicleDraftModel draft);
  Future<void> saveFoto(File foto, String targa);
  Future<File?> readFoto(String targa);
  String getFotoPath(String targa);
}

class VehicleDraftLocalDataSourceImpl implements VehicleDraftLocalDataSource {
  static const _draftKey = 'vehicle_draft';

  final SharedPreferences prefs;
  final String dirPAth;

  VehicleDraftLocalDataSourceImpl(this.prefs, {required this.dirPAth});

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

  @override
  Future<void> saveFoto(File foto, String targa) async {
    try {
      final String percorsoFinale = '$dirPAth/veicolo_$targa.jpg';
      await foto.copy(percorsoFinale);
    } catch (e) {
      throw CacheException('Errore salvataggio foto: $e');
    }
  }

  @override
  Future<File?> readFoto(String targa) async {
    try {
      final file = File('$dirPAth/veicolo_$targa.jpg');
      if (await file.exists()) return file;
      return null;
    } catch (e) {
      throw CacheException('Errore lettura foto: $e');
    }
  }

  @override
  String getFotoPath(String targa) {
    final path = '$dirPAth/veicolo_$targa.jpg';
    return File(path).existsSync() ? path : '';
  }
}
