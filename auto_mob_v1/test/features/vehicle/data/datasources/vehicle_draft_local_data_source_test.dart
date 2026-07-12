// =====================================================================
//  TEST — DATA SOURCE locale foto veicolo (layer data)
// ---------------------------------------------------------------------
//  Verifica il fix del freeze/cache foto: il nome file e' VERSIONATO col
//  timestamp (path diverso ad ogni salvataggio -> niente cache stantia di
//  FileImage), il nome corrente e' in SharedPreferences (getFotoPath senza
//  I/O), e la foto precedente viene cancellata. Usa file reali in una
//  cartella temporanea + SharedPreferences mockato.
// =====================================================================

import 'dart:io';

import 'package:auto_mob_v1/core/error/exceptions/exceptions.dart';
import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_draft_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late SharedPreferences prefs;
  late VehicleDraftLocalDataSourceImpl dataSource;

  const targa = 'AB123CD';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('am_foto_test');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = VehicleDraftLocalDataSourceImpl(prefs, dirPAth: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Crea un file sorgente con un contenuto noto da "scegliere" col picker.
  Future<File> sorgente(String contenuto) async {
    final f = File('${tempDir.path}/src_${contenuto.hashCode}.jpg');
    await f.writeAsString(contenuto);
    return f;
  }

  group('saveFoto + getFotoPath', () {
    test('scrive un file versionato e registra il nome in prefs', () async {
      final src = await sorgente('foto-1');

      await dataSource.saveFoto(src, targa);

      final path = dataSource.getFotoPath(targa);
      expect(path, isNotEmpty);
      // Nome versionato: contiene la targa ma NON e' il vecchio schema fisso.
      expect(path, contains('veicolo_${targa}_'));
      expect(path, isNot(endsWith('veicolo_$targa.jpg')));
      expect(File(path).existsSync(), isTrue);
      expect(await File(path).readAsString(), 'foto-1');
    });

    test('un secondo salvataggio cambia il path (cache-busting) e cancella il vecchio file',
        () async {
      await dataSource.saveFoto(await sorgente('foto-1'), targa);
      final primoPath = dataSource.getFotoPath(targa);

      // Il timestamp e' al millisecondo: garantiamo un istante diverso.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await dataSource.saveFoto(await sorgente('foto-2'), targa);
      final secondoPath = dataSource.getFotoPath(targa);

      expect(secondoPath, isNot(primoPath)); // path nuovo -> chiave cache nuova
      expect(File(secondoPath).existsSync(), isTrue);
      expect(await File(secondoPath).readAsString(), 'foto-2');
      // Il file precedente e' stato rimosso (niente accumulo di copie).
      expect(File(primoPath).existsSync(), isFalse);
    });

    test('getFotoPath ritorna stringa vuota quando non c\'e\' nessuna foto', () {
      expect(dataSource.getFotoPath('MAI_SALVATA'), '');
    });

    test('fallback legacy: trova la vecchia foto non versionata su disco', () async {
      // Simula un utente pre-esistente: file col vecchio schema, nessuna prefs.
      final legacy = File('${tempDir.path}/veicolo_$targa.jpg');
      await legacy.writeAsString('vecchia');

      expect(dataSource.getFotoPath(targa), legacy.path);
    });

    test('cambiando foto, lo schema legacy viene cancellato', () async {
      final legacy = File('${tempDir.path}/veicolo_$targa.jpg');
      await legacy.writeAsString('vecchia');

      await dataSource.saveFoto(await sorgente('nuova'), targa);

      expect(legacy.existsSync(), isFalse);
      expect(dataSource.getFotoPath(targa), contains('veicolo_${targa}_'));
    });

    test('saveFoto lancia CacheException se il sorgente non esiste', () async {
      final inesistente = File('${tempDir.path}/non_esiste.jpg');

      expect(
        () => dataSource.saveFoto(inesistente, targa),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('readFoto', () {
    test('ritorna il file corrente dopo un salvataggio', () async {
      await dataSource.saveFoto(await sorgente('foto'), targa);

      final file = await dataSource.readFoto(targa);

      expect(file, isNotNull);
      expect(await file!.readAsString(), 'foto');
    });

    test('ritorna null se non c\'e\' nessuna foto', () async {
      expect(await dataSource.readFoto('MAI_SALVATA'), isNull);
    });
  });
}
