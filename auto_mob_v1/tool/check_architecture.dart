// =====================================================================
//  CHECK ARCHITECTURE  —  il "guardiano" della Clean Architecture
// ---------------------------------------------------------------------
//  Scansiona lib/ e BLOCCA (exit code 1) se trova violazioni delle
//  regole architetturali. Nessuna dipendenza esterna: solo dart:io.
//
//  Lancialo con:   dart run tool/check_architecture.dart
//
//  Escape hatch: se una riga contiene il commento  // arch-ignore
//  lo script la salta (usare con parsimonia, solo per falsi positivi).
// =====================================================================

// ignore_for_file: avoid_print -- e' uno script CLI, il print e' l'output.

import 'dart:io';

// File che elenca le violazioni gia' note (DEBITO TECNICO tracciato).
// Quelle presenti qui NON fanno fallire il check: si bloccano solo le NUOVE.
const baselineFile = 'tool/arch_baseline.txt';

// I SOLI pacchetti che il DOMAIN puo' importare. Tutto il resto
// (Flutter, supabase, get_it, go_router, bloc...) e' VIETATO nel domain:
// il domain deve essere Dart puro. Aggiungi qui se davvero serve.
const domainAllowedPackages = <String>{
  'fpdart',
  'equatable',
  'meta',
  'collection',
};

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln(
        'ERRORE: cartella lib/ non trovata. Lancia lo script dalla root del progetto.');
    exit(2);
  }

  final violations = <_Violation>[];

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    // Salta i file generati automaticamente
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }

    final rel = _libRelative(entity.path); // es: features/vehicle/data/...
    final src = _classify(rel);
    final lines = entity.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNo = i + 1;

      // Escape hatch per falsi positivi
      if (line.contains('arch-ignore')) continue;

      // ---- Regole sugli IMPORT ----
      final imp = _parseImport(line);
      if (imp != null) {
        _checkImport(src, imp, rel, lineNo, violations);
      }

      // ---- Regola 13: niente funzioni che ritornano Widget ----
      _checkWidgetFunction(line, rel, lineNo, violations);
    }
  }

  // -------------------- REPORT --------------------
  // Separa le violazioni gia' note (baseline) da quelle NUOVE.
  final baseline = _loadBaseline();
  final nuove = <_Violation>[];
  var baselinate = 0;
  for (final v in violations) {
    if (baseline.contains(v.signature)) {
      baselinate++;
    } else {
      nuove.add(v);
    }
  }

  if (baselinate > 0) {
    print(
        '($baselinate violazioni a BASELINE — debito tecnico tracciato in $baselineFile / docs/TECH_DEBT.md)');
  }

  if (nuove.isEmpty) {
    print('OK  Nessuna NUOVA violazione architetturale.');
    exit(0);
  }

  nuove.sort((a, b) {
    final c = a.file.compareTo(b.file);
    return c != 0 ? c : a.line.compareTo(b.line);
  });

  print('FAIL  Trovate ${nuove.length} NUOVE violazioni architetturali:\n');
  for (final v in nuove) {
    print('  ${v.file}:${v.line}');
    print('     [${v.rule}] ${v.message}\n');
  }
  exit(1);
}

// Carica il baseline: una firma per riga, ignora righe vuote e commenti (#).
Set<String> _loadBaseline() {
  final f = File(baselineFile);
  if (!f.existsSync()) return <String>{};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}

// =====================================================================
//  CLASSIFICAZIONE DEI FILE
// =====================================================================

// Il "composition root": gli unici punti del core autorizzati a montare le
// feature (dependency injection e configurazione delle rotte).
bool _isCompositionRoot(String rel) =>
    rel.startsWith('core/di/') || rel.startsWith('core/router/');

// Ritorna la path relativa a lib/ (posix), es: features/vehicle/data/foo.dart
String _libRelative(String path) {
  final p = path.replaceAll('\\', '/');
  final idx = p.indexOf('lib/');
  return idx == -1 ? p : p.substring(idx + 'lib/'.length);
}

class _FileInfo {
  final String layer; // domain | data | presentation | core | other
  final String? feature; // nome feature, se sotto features/<x>/
  final bool isBloc; // file *_bloc.dart o *_cubit.dart
  final bool isDatasource;

  _FileInfo(this.layer, this.feature, this.isBloc, this.isDatasource);
}

_FileInfo _classify(String rel) {
  String layer;
  if (rel.contains('/domain/')) {
    layer = 'domain';
  } else if (rel.contains('/data/')) {
    layer = 'data';
  } else if (rel.contains('/presentation/')) {
    layer = 'presentation';
  } else if (rel.startsWith('core/')) {
    layer = 'core';
  } else {
    layer = 'other';
  }

  String? feature;
  final m = RegExp(r'^features/([^/]+)/').firstMatch(rel);
  if (m != null) feature = m.group(1);

  final fname = rel.split('/').last;
  final isBloc = fname.endsWith('_bloc.dart') || fname.endsWith('_cubit.dart');
  final isDatasource = fname.contains('datasource') ||
      fname.contains('data_source') ||
      rel.contains('/datasources/');

  return _FileInfo(layer, feature, isBloc, isDatasource);
}

// =====================================================================
//  CONTROLLO IMPORT
// =====================================================================

String? _parseImport(String line) {
  final m = RegExp('''^\\s*import\\s+['"]([^'"]+)['"]''').firstMatch(line);
  return m?.group(1);
}

void _checkImport(_FileInfo src, String target, String srcRel, int lineNo,
    List<_Violation> out) {
  void add(String rule, String msg) =>
      out.add(_Violation(srcRel, lineNo, rule, msg));

  // dart:core, dart:async... sempre ammessi
  if (target.startsWith('dart:')) return;

  // ---- Import ESTERNO (package:...) ----
  if (target.startsWith('package:')) {
    final pkg = target.substring('package:'.length).split('/').first;

    // Il nostro stesso package: trattalo come path interno
    if (pkg == 'auto_mob_v1') {
      final internal = target.substring('package:auto_mob_v1/'.length);
      _applyInternalRules(src, internal, srcRel, lineNo, out);
      return;
    }

    // Regola 3+4: il DOMAIN puo' importare solo pochi pacchetti puri
    if (src.layer == 'domain' && !domainAllowedPackages.contains(pkg)) {
      add('R3/R4',
          'Il DOMAIN deve essere Dart puro: vietato importare "$pkg" (ammessi solo: ${domainAllowedPackages.join(", ")}).');
      return;
    }

    // Regola 11: il BLoC non conosce go_router
    if (src.isBloc && pkg == 'go_router') {
      add('R11',
          'Un BLoC non deve importare go_router: la navigazione e\' compito della UI.');
    }

    // Regola 12: il BLoC non importa la UI di Flutter (material/widgets/cupertino)
    if (src.isBloc && pkg == 'flutter') {
      final sub = target.substring('package:flutter/'.length);
      if (sub.startsWith('material') ||
          sub.startsWith('widgets') ||
          sub.startsWith('cupertino')) {
        add('R12',
            'Un BLoC deve essere UI-agnostic: vietato importare "$target" (usa foundation se ti serve @immutable).');
      }
    }
    return;
  }

  // ---- Import RELATIVO (../ , ./) ----
  final resolved = _resolveRelative(srcRel, target);
  if (resolved == null) return;
  _applyInternalRules(src, resolved, srcRel, lineNo, out);
}

// Regole che valgono quando il target e' un file interno a lib/
void _applyInternalRules(_FileInfo src, String targetRel, String srcRel,
    int lineNo, List<_Violation> out) {
  void add(String rule, String msg) =>
      out.add(_Violation(srcRel, lineNo, rule, msg));

  final tgt = _classify(targetRel);

  // R1/R2: il domain non guarda verso l'esterno
  if (src.layer == 'domain' && tgt.layer == 'data') {
    add('R1', 'Il DOMAIN non deve importare il layer DATA.');
  }
  if (src.layer == 'domain' && tgt.layer == 'presentation') {
    add('R2', 'Il DOMAIN non deve importare il layer PRESENTATION.');
  }

  // R5: data non importa presentation
  if (src.layer == 'data' && tgt.layer == 'presentation') {
    add('R5', 'Il layer DATA non deve importare la PRESENTATION.');
  }

  // R6: presentation non importa data (deve passare dagli usecase del domain)
  if (src.layer == 'presentation' && tgt.layer == 'data') {
    add('R6',
        'La PRESENTATION non deve importare il layer DATA: passa dagli usecase/interfacce del domain.');
  }

  // R7: un datasource non importa un repository (verso: repository -> datasource)
  if (src.isDatasource && targetRel.contains('/repositories/')) {
    add('R7',
        'Un datasource non deve importare un repository (il verso corretto e\' repository -> datasource).');
  }

  // R8: il core non conosce le feature.
  // ECCEZIONE: il "composition root" (DI + router) e' il punto in cui si
  // monta l'app, sta SOPRA i layer e per forza vede tutte le feature.
  if (src.layer == 'core' &&
      !_isCompositionRoot(srcRel) &&
      targetRel.startsWith('features/')) {
    add('R8',
        'Il CORE non deve importare una feature: il core e\' trasversale. (Se e\' glue di montaggio, va in core/di o core/router.)');
  }

  // R9 (morbida): cross-feature ammesso SOLO verso il domain dell'altra feature
  if (src.feature != null &&
      tgt.feature != null &&
      src.feature != tgt.feature &&
      tgt.layer != 'domain') {
    add('R9',
        'Cross-feature: "${src.feature}" puo\' importare solo il DOMAIN di "${tgt.feature}", non il layer ${tgt.layer.toUpperCase()}.');
  }

  // R10: un BLoC non importa un altro BLoC
  if (src.isBloc && tgt.isBloc && targetRel != srcRel) {
    add('R10',
        'Un BLoC non deve importare un altro BLoC (accoppiamento vietato: comunica via UI o usecase condiviso).');
  }
}

// Risolve un import relativo (../ , ./) rispetto al file che lo contiene,
// restituendo una path relativa a lib/ (es: features/vehicle/domain/...).
String? _resolveRelative(String srcRel, String target) {
  if (!target.startsWith('.')) return null; // non relativo -> ignora
  final dir =
      srcRel.contains('/') ? srcRel.substring(0, srcRel.lastIndexOf('/')) : '';
  final parts = <String>[];
  if (dir.isNotEmpty) parts.addAll(dir.split('/'));
  for (final seg in target.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

// =====================================================================
//  REGOLA 13 — niente funzioni/metodi che ritornano Widget
// =====================================================================

// Cattura "Widget nome(" oppure "Widget? nome(" NON preceduto da lettera
// (cosi' Future<Widget>, MyWidget... non scattano).
final _widgetFnRe = RegExp(r'(?<![A-Za-z0-9_])Widget\??\s+(\w+)\s*\(');

void _checkWidgetFunction(
    String line, String rel, int lineNo, List<_Violation> out) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('*')) return; // commenti

  final m = _widgetFnRe.firstMatch(line);
  if (m == null) return;

  final name = m.group(1);
  // Eccezioni ammesse: l'override build() e i tipi funzione (Widget Function())
  if (name == 'build' || name == 'Function') return;

  out.add(_Violation(rel, lineNo, 'R13',
      'Niente funzioni che ritornano Widget ("$name"): estrai una widget class privata. Se e\' riutilizzabile mettila in core/widgets, altrimenti nella feature corrente.'));
}

// =====================================================================

class _Violation {
  final String file;
  final int line;
  final String rule;
  final String message;
  _Violation(this.file, this.line, this.rule, this.message);

  // Firma stabile usata per confrontare col baseline.
  String get signature => '$file:$line:$rule';
}
