import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/Exception/Exceptions.dart';
import '../models/vehicle_draft_model.dart';

abstract class VehicleDraftLocalDataSource {
  /// Salva il draft in SharedPreferences. Lancia [CacheException] in caso di errore.
  Future<void> saveDraft(VehicleDraftModel draft);
  Future<void> saveFoto(File foto, String targa);
  Future<File> readFoto( String targa);
}

class VehicleDraftLocalDataSourceImpl implements VehicleDraftLocalDataSource {
  static const _draftKey = 'vehicle_draft';

  final SharedPreferences prefs;
  final String dirPAth;

  VehicleDraftLocalDataSourceImpl(this.prefs, {required this.dirPAth} );

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


      // 2. Genera il nome univoco del file

      final String nomeFile = 'veicolo_${targa}.jpg';

      // 3. Unisci la cartella al nome del file
      final String percorsoFinale = '${dir.path}/$nomeFile';

      // 4. Copia il file temporaneo nel percorso definitivo
      final File fileSalvato = await foto.copy(percorsoFinale);
    } catch (e) {
      throw CacheException('Errore salvataggio foto: $e');
    }
  }

  @override
  Future<File> readFoto(String targa) {
    // TODO: implement readFoto
    throw UnimplementedError();
  }
  

}
