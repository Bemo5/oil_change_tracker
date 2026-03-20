import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../vehicles/data/hive_boxes.dart';
import 'maintenance_item.dart';
import 'maintenance_type.dart';

class MaintenanceItemRepo {
  final Uuid _uuid = const Uuid();

  Box<Map> _box() => HiveBoxes.maintenanceItemsBox();

  List<MaintenanceItem> getAllSync() {
    return _box()
        .values
        .map((m) => MaintenanceItem.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  List<MaintenanceItem> getForVehicle(String vehicleId) {
    return _box()
        .values
        .map((m) => MaintenanceItem.fromMap(Map<String, dynamic>.from(m)))
        .where((item) => item.vehicleId == vehicleId)
        .toList();
  }

  Future<MaintenanceItem> addForVehicle({
    required String vehicleId,
    required String typeId,
    required String typeName,
    String category = '',
    required int intervalKm,
    required int intervalMonths,
    required int savedOdometerKm,
    DateTime? lastServiceDate,
  }) async {
    final item = MaintenanceItem(
      id: _uuid.v4(),
      vehicleId: vehicleId,
      typeId: typeId,
      typeName: typeName,
      category: category,
      intervalKm: intervalKm,
      intervalMonths: intervalMonths,
      savedOdometerKm: savedOdometerKm,
      lastServiceDate: lastServiceDate,
    );
    await _box().put(item.id, item.toMap());
    return item;
  }

  Future<void> addAllTypesForVehicle(
    String vehicleId,
    int currentOdometerKm,
    List<MaintenanceType> types,
  ) async {
    for (final t in types) {
      await addForVehicle(
        vehicleId: vehicleId,
        typeId: t.id,
        typeName: t.name,
        category: t.category,
        intervalKm: t.defaultIntervalKm,
        intervalMonths: t.defaultIntervalMonths,
        savedOdometerKm: currentOdometerKm,
      );
    }
  }

  Future<void> markDone(MaintenanceItem item, int currentOdometerKm, {double? priceEgp}) async {
    final updated = item.copyWith(
      savedOdometerKm: currentOdometerKm,
      lastServiceDate: DateTime.now(),
      lastPriceEgp: priceEgp,
    );
    await _box().put(updated.id, updated.toMap());
  }

  Future<void> update(MaintenanceItem item) async {
    await _box().put(item.id, item.toMap());
  }

  Future<void> delete(String id) async {
    await _box().delete(id);
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

  Future<void> putAll(List<MaintenanceItem> items) async {
    for (final item in items) {
      await _box().put(item.id, item.toMap());
    }
  }
}
