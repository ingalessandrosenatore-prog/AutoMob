import 'work_log_parts_catalog.dart';

class WorkLogPartsData {
  const WorkLogPartsData({required this.catalog, required this.presets});

  final Map<int, WorkLogPartCatalogEntry> catalog;
  final Map<String, List<int>> presets;
}
