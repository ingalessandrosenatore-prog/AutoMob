import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/italian_municipality_model.dart';

abstract interface class MunicipalityLocalDataSource {
  Future<List<ItalianMunicipalityModel>> getMunicipalities();
}

final class MunicipalityLocalDataSourceImpl
    implements MunicipalityLocalDataSource {
  const MunicipalityLocalDataSourceImpl();

  static const _assetPath = 'assets/data/italian_municipalities.json';

  @override
  Future<List<ItalianMunicipalityModel>> getMunicipalities() async {
    final raw = await rootBundle.loadString(_assetPath);
    final rows = jsonDecode(raw) as List<dynamic>;
    return rows
        .cast<Map<String, dynamic>>()
        .map(ItalianMunicipalityModel.fromJson)
        .toList(growable: false);
  }
}
