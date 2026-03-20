import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../vehicles/data/hive_boxes.dart';
import 'maintenance_type.dart';

class MaintenanceTypeRepo {
  final Uuid _uuid = const Uuid();

  Box<Map> _box() => HiveBoxes.maintenanceTypesBox();

  List<MaintenanceType> getAllSync() {
    return _box()
        .values
        .map((m) => MaintenanceType.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<MaintenanceType> add({
    required String name,
    int defaultIntervalKm = 5000,
    int defaultIntervalMonths = 6,
  }) async {
    final t = MaintenanceType(
      id: _uuid.v4(),
      name: name,
      defaultIntervalKm: defaultIntervalKm,
      defaultIntervalMonths: defaultIntervalMonths,
    );
    await _box().put(t.id, t.toMap());
    return t;
  }

  Future<void> update(MaintenanceType t) async {
    await _box().put(t.id, t.toMap());
  }

  Future<void> delete(String id) async {
    await _box().delete(id);
  }

  Future<void> clearAll() async => await _box().clear();

  Future<void> putAll(List<MaintenanceType> types) async {
    for (final t in types) {
      await _box().put(t.id, t.toMap());
    }
  }

  Future<void> seedDefaults() async {
    if (_box().isNotEmpty) return;
    await add(name: 'Oil Change', defaultIntervalKm: 5000, defaultIntervalMonths: 6);
    await add(name: 'Air Filter', defaultIntervalKm: 20000, defaultIntervalMonths: 12);
    await add(name: 'Brake Pads', defaultIntervalKm: 40000, defaultIntervalMonths: 24);
    await add(name: 'Tires', defaultIntervalKm: 50000, defaultIntervalMonths: 48);
  }
}
