import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions/exceptions.dart';
import '../models/vehicle_draft_model.dart';

abstract class VehicleDraftLocalDataSource {
  /// Salva il draft in SharedPreferences. Lancia [CacheException] in caso di errore.
  Future<void> saveDraft(VehicleDraftModel draft);
  Future<VehicleDraftModel?> loadDraft();
  Future<void> clearDraft();
  Future<void> saveFoto(File foto, String targa);
  Future<File?> readFoto(String targa);
  String getFotoPath(String targa);
}

class VehicleDraftLocalDataSourceImpl implements VehicleDraftLocalDataSource {
  static const _draftKey = 'vehicle_draft';

  /// Prefisso della chiave che, per ogni targa, tiene il NOME del file foto
  /// corrente (versionato col timestamp). Salviamo il nome, non il path
  /// assoluto: su iOS la cartella documents puo' cambiare tra i riavvii.
  static const _fotoKeyPrefix = 'vehicle_photo_';

  final SharedPreferences prefs;
  final String dirPAth;

  VehicleDraftLocalDataSourceImpl(this.prefs, {required this.dirPAth});

  /// Supabase restituisce la targa in minuscolo, mentre il form la usa in
  /// maiuscolo. La foto deve quindi avere una sola chiave canonica locale.
  String _normalizeTarga(String targa) => targa.trim().toUpperCase();

  String _fotoPrefsKey(String targa) =>
      '$_fotoKeyPrefix${_normalizeTarga(targa)}';

  String _legacyLowercaseFotoPrefsKey(String targa) =>
      '$_fotoKeyPrefix${_normalizeTarga(targa).toLowerCase()}';

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
  Future<VehicleDraftModel?> loadDraft() async {
    try {
      final value = prefs.getString(_draftKey);
      if (value == null || value.isEmpty) return null;
      return VehicleDraftModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(value) as Map),
      );
    } catch (e) {
      throw CacheException('Errore lettura draft: $e');
    }
  }

  @override
  Future<void> clearDraft() async {
    final ok = await prefs.remove(_draftKey);
    if (!ok && prefs.containsKey(_draftKey)) {
      throw const CacheException('Eliminazione draft fallita');
    }
  }

  @override
  Future<void> saveFoto(File foto, String targa) async {
    try {
      final targaNormalizzata = _normalizeTarga(targa);
      // Nome versionato col timestamp: ad ogni cambio foto il PATH e' diverso.
      // Cosi' FileImage (che usa il path come chiave della cache immagini in
      // RAM) non serve mai i byte vecchi -> la foto nuova compare subito,
      // senza svuotare la cache a mano (fragile) ne' riavviare l'app.
      final String nomeFile =
          'veicolo_${targaNormalizzata}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await foto.copy('$dirPAth/$nomeFile');

      // Cancella la foto precedente (nome in prefs + eventuale legacy non
      // versionato) per non accumulare copie ad ogni modifica.
      final vecchiNomi = <String>{
        ?prefs.getString(_fotoPrefsKey(targaNormalizzata)),
        ?prefs.getString(_legacyLowercaseFotoPrefsKey(targaNormalizzata)),
      };
      await _cancellaVecchieFoto(
        targaNormalizzata,
        tieni: nomeFile,
        vecchiNomi: vecchiNomi,
      );

      // Registra il nome corrente: getFotoPath lo legge senza toccare il disco.
      final salvata = await prefs.setString(
        _fotoPrefsKey(targaNormalizzata),
        nomeFile,
      );
      if (!salvata) {
        throw const CacheException('Indice locale della foto non salvato');
      }

      // Pulisce l'eventuale chiave creata dalle versioni precedenti quando la
      // targa proveniva dal database in minuscolo.
      final legacyKey = _legacyLowercaseFotoPrefsKey(targaNormalizzata);
      if (legacyKey != _fotoPrefsKey(targaNormalizzata)) {
        await prefs.remove(legacyKey);
      }
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException('Errore salvataggio foto: $e');
    }
  }

  /// Cancella i vecchi file foto del veicolo, tranne [tieni] (quello appena
  /// scritto). Best-effort: eventuali errori di delete non sono fatali.
  Future<void> _cancellaVecchieFoto(
    String targa, {
    required String tieni,
    required Set<String> vecchiNomi,
  }) async {
    final candidati = <String>{
      ...vecchiNomi,
      'veicolo_$targa.jpg', // schema legacy non versionato
      'veicolo_${targa.toLowerCase()}.jpg',
    };
    for (final nome in candidati) {
      if (nome == tieni) continue;
      final f = File('$dirPAth/$nome');
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {
          /* best-effort */
        }
      }
    }
  }

  @override
  Future<File?> readFoto(String targa) async {
    try {
      final path = getFotoPath(targa);
      if (path.isEmpty) return null;
      final file = File(path);
      if (await file.exists()) return file;
      return null;
    } catch (e) {
      throw CacheException('Errore lettura foto: $e');
    }
  }

  @override
  String getFotoPath(String targa) {
    // Nome corrente da prefs (in RAM, zero I/O): niente existsSync per veicolo
    // ad ogni caricamento della lista.
    final targaNormalizzata = _normalizeTarga(targa);
    final nome =
        prefs.getString(_fotoPrefsKey(targaNormalizzata)) ??
        prefs.getString(_legacyLowercaseFotoPrefsKey(targaNormalizzata));
    if (nome != null) return '$dirPAth/$nome';

    // Fallback legacy: utenti che avevano gia' una foto col vecchio schema
    // non versionato. Un solo existsSync una-tantum, finche' non ricambiano la
    // foto (dopodiche' si passa allo schema versionato + prefs).
    final legacyMaiuscolo = '$dirPAth/veicolo_$targaNormalizzata.jpg';
    if (File(legacyMaiuscolo).existsSync()) return legacyMaiuscolo;
    final legacyMinuscolo =
        '$dirPAth/veicolo_${targaNormalizzata.toLowerCase()}.jpg';
    return File(legacyMinuscolo).existsSync() ? legacyMinuscolo : '';
  }
}
