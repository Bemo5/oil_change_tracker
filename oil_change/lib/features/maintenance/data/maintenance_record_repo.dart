import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../vehicles/data/hive_boxes.dart';
import 'maintenance_record.dart';

class MaintenanceRecordRepo {
  final Uuid _uuid = const Uuid();

  Box<Map> _box() => HiveBoxes.maintenanceRecordsBox();

  List<MaintenanceRecord> getAllSync() {
    return _box()
        .values
        .map((m) => MaintenanceRecord.fromMap(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<MaintenanceRecord> getForVehicle(String vehicleId) {
    return _box()
        .values
        .map((m) => MaintenanceRecord.fromMap(Map<String, dynamic>.from(m)))
        .where((r) => r.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> add({
    required String vehicleId,
    required String typeId,
    required String typeName,
    required int odometerKm,
    double? priceEgp,
  }) async {
    final record = MaintenanceRecord(
      id: _uuid.v4(),
      vehicleId: vehicleId,
      typeId: typeId,
      typeName: typeName,
      odometerKm: odometerKm,
      date: DateTime.now(),
      priceEgp: priceEgp,
    );
    await _box().put(record.id, record.toMap());
  }

  Future<void> deleteForVehicle(String vehicleId) async {
    final box = _box();
    final keys = box.keys.where((key) {
      final map = box.get(key);
      return map != null && map['vehicleId'] == vehicleId;
    }).toList();
    await box.deleteAll(keys);
  }

  Future<void> deleteByTypeId(String typeId) async {
    final box = _box();
    final keys = box.keys.where((key) {
      final map = box.get(key);
      return map != null && map['typeId'] == typeId;
    }).toList();
    await box.deleteAll(keys);
  }

  Future<void> clearAll() async => await _box().clear();

  Future<void> putAll(List<MaintenanceRecord> records) async {
    for (final r in records) {
      await _box().put(r.id, r.toMap());
    }
  }
}
