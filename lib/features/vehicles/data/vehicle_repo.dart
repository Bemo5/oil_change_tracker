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
    int defaultIntervalKm = 5000,
    int timeSuggestionMonths = 6,
    String? photoPath,
  }) async {
    final box = _box();

    final vehicle = Vehicle(
      id: _uuid.v4(),
      name: name,
      // On first create, assume last oil change baseline = current
      savedOdometerKm: initialOdometerKm,
      currentOdometerKm: initialOdometerKm,
      defaultIntervalKm: defaultIntervalKm,
      timeSuggestionMonths: timeSuggestionMonths,
      photoPath: photoPath,
    );

    await box.put(vehicle.id, vehicle.toMap());
    return vehicle;
  }

  Future<void> update(Vehicle vehicle) async {
    final box = _box();
    await box.put(vehicle.id, vehicle.toMap());
  }

  Future<void> delete(String id) async {
    final box = _box();
    await box.delete(id);
  }
}
