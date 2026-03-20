import 'dart:convert';

import '../../vehicles/data/vehicle.dart';
import '../../vehicles/data/vehicle_repo.dart';
import 'maintenance_type.dart';
import 'maintenance_type_repo.dart';
import 'maintenance_item.dart';
import 'maintenance_item_repo.dart';
import 'maintenance_record.dart';
import 'maintenance_record_repo.dart';

class BackupService {
  final _vehicleRepo = VehicleRepo();
  final _typeRepo = MaintenanceTypeRepo();
  final _itemRepo = MaintenanceItemRepo();
  final _recordRepo = MaintenanceRecordRepo();

  /// Returns the JSON string of all data.
  String exportToJson() {
    final data = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': _vehicleRepo.getAllSync().map((v) => v.toMap()).toList(),
      'maintenanceTypes': _typeRepo.getAllSync().map((t) => t.toMap()).toList(),
      'maintenanceItems': _itemRepo.getAllSync().map((i) => i.toMap()).toList(),
      'maintenanceRecords': _recordRepo.getAllSync().map((r) => r.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Imports data from a JSON string. Replaces all existing data.
  Future<void> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    final vehicles = (data['vehicles'] as List)
        .map((m) => Vehicle.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    final types = (data['maintenanceTypes'] as List)
        .map((m) => MaintenanceType.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    final items = (data['maintenanceItems'] as List)
        .map((m) => MaintenanceItem.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    final records = (data['maintenanceRecords'] as List)
        .map((m) => MaintenanceRecord.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();

    await _vehicleRepo.clearAll();
    await _typeRepo.clearAll();
    await _itemRepo.clearAll();
    await _recordRepo.clearAll();

    await _vehicleRepo.putAll(vehicles);
    await _typeRepo.putAll(types);
    await _itemRepo.putAll(items);
    await _recordRepo.putAll(records);
  }
}
