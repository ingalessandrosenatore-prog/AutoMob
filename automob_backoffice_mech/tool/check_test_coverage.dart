// =====================================================================
//  CHECK TEST COVERAGE  —  applica la disciplina TDD
// ---------------------------------------------------------------------
//  Ogni usecase, repository (impl) e bloc/cubit DEVE essere importato da
//  almeno un test reale. Il nome convenzionale rimane consigliato, ma sono
//  ammessi test aggregati se importano esplicitamente il file produttivo.
//
//  Perche': senza questo controllo, "flutter test" resta verde anche se
//  non hai scritto NESSUN test per la logica nuova che hai aggiunto —
//  non c'e' nulla che possa fallire se il test non esiste proprio.
//
//  Lancialo con:   dart run tool/check_test_coverage.dart
//                 (dal root del progetto automob_backoffice_mech/)
// =====================================================================

// ignore_for_file: avoid_print -- e' uno script CLI, il print e' l'output.

import 'dart:io';

// Debito pre-esistente (codice senza test scritto prima di questo check).
// Quando scrivi il test per uno di questi file, CANCELLA la riga qui.
String get baselineFile => '${_projectRoot()}/tool/test_baseline.txt';

String _projectRoot() {
  return File.fromUri(Platform.script).parent.parent.path;
}

void main() {
  final libDir = Directory('${_projectRoot()}/lib');
  if (!libDir.existsSync()) {
    stderr.writeln('ERRORE: cartella lib/ non trovata.');
    exit(2);
  }

  final requiresTest =
      <String>[]; // path relativi a lib/, es: features/x/domain/usecases/y.dart
  final testDir = Directory('${_projectRoot()}/test');
  final testFiles = testDir.existsSync()
      ? testDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('_test.dart'))
            .map((file) => _TestFile(content: file.readAsStringSync()))
            .where((test) => test.hasTestDeclaration)
            .toList()
      : <_TestFile>[];

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }

    final rel = _libRelative(entity.path);
    if (_needsTest(rel)) requiresTest.add(rel);
  }

  final baseline = _loadBaseline();
  final missing = <String>[];
  var baselinate = 0;

  for (final rel in requiresTest) {
    if (testFiles.any((test) => test.covers(rel))) continue;

    if (baseline.contains(rel)) {
      baselinate++;
    } else {
      missing.add(rel);
    }
  }

  if (baselinate > 0) {
    print(
      '($baselinate file senza test a BASELINE — debito tracciato in $baselineFile)',
    );
  }

  if (missing.isEmpty) {
    print('OK  Tutta la logica (usecase/repository/bloc) ha un test.');
    exit(0);
  }

  missing.sort();
  print(
    'FAIL  ${missing.length} file di logica SENZA test (nuovi, non a baseline):\n',
  );
  for (final rel in missing) {
    print('  lib/$rel');
    print('     atteso: un *_test.dart che importi esplicitamente questo file');
    print('     convenzione: test/${_expectedTestRelPath(rel)}\n');
  }
  exit(1);
}

// File che richiedono un test: usecase, repository impl, bloc/cubit.
bool _needsTest(String rel) {
  if (rel.contains('/domain/usecases/')) return true;
  if (rel.contains('/data/repositories/')) return true;

  if (rel.contains('/presentation/bloc/')) {
    final name = rel.split('/').last;
    if (name.endsWith('_bloc.dart') || name.endsWith('_cubit.dart')) {
      return true;
    }
  }
  return false;
}

// lib/features/x/domain/usecases/y.dart -> test/features/x/domain/usecases/y_test.dart
String _expectedTestRelPath(String libRel) {
  final withoutExt = libRel.substring(0, libRel.length - '.dart'.length);
  return '$withoutExt'
      '_test.dart';
}

String _libRelative(String path) {
  final p = path.replaceAll('\\', '/');
  final idx = p.indexOf('lib/');
  return idx == -1 ? p : p.substring(idx + 'lib/'.length);
}

Set<String> _loadBaseline() {
  final f = File(baselineFile);
  if (!f.existsSync()) return <String>{};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}

final class _TestFile {
  const _TestFile({required this.content});

  final String content;

  bool get hasTestDeclaration => RegExp(
    r'\b(test|testWidgets|blocTest)\s*(<[^>]+>)?\s*\(',
  ).hasMatch(content);

  bool covers(String libRel) {
    final packageImport = 'package:automob_backoffice_mech/$libRel';
    if (content.contains(packageImport)) return true;

    // Supporta anche import relativi nei test mantenendo un controllo
    // conservativo sul nome del file produttivo.
    final fileName = libRel.split('/').last;
    return content.contains("import '") && content.contains(fileName);
  }
}
