import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

import 'hive_boxes.dart';
import 'vehicle.dart';

class VehicleRepo {
  final Uuid _uuid = const Uuid();

  Box<Map> _box() => HiveBoxes.vehiclesBox();

  List<Vehicle> getAllSync() {
    final Box<Map> box = _box();
    return box.values
        .map((m) => Vehicle.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Vehicle> add({
    required String name,
    required int initialOdometerKm,
    String? photoPath,
  }) async {
    final vehicle = Vehicle(
      id: _uuid.v4(),
      name: name,
      currentOdometerKm: initialOdometerKm,
      photoPath: photoPath,
    );
    await _box().put(vehicle.id, vehicle.toMap());
    return vehicle;
  }

  Future<void> update(Vehicle vehicle) async {
    await _box().put(vehicle.id, vehicle.toMap());
  }

  Future<void> delete(String id) async {
    await _box().delete(id);
  }

  Future<void> clearAll() async => await _box().clear();

  Future<void> putAll(List<Vehicle> vehicles) async {
    for (final v in vehicles) {
      await _box().put(v.id, v.toMap());
    }
  }
}
