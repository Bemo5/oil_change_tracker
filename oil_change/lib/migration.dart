import 'features/vehicles/data/hive_boxes.dart';
import 'features/maintenance/data/maintenance_type_repo.dart';
import 'features/maintenance/data/maintenance_item_repo.dart';
import 'features/maintenance/data/maintenance_record_repo.dart';

Future<void> migrateV1ToV2() async {
  final meta = HiveBoxes.metaBox();
  if (meta.get('v2_migrated') == true) return;

  final typeRepo = MaintenanceTypeRepo();
  final itemRepo = MaintenanceItemRepo();
  final recordRepo = MaintenanceRecordRepo();

  // Seed default types
  await typeRepo.seedDefaults();
  final types = typeRepo.getAllSync();

  // Find the "Oil Change" type
  final oilType = types.firstWhere(
    (t) => t.name == 'Oil Change',
    orElse: () => types.first,
  );

  // Migrate existing vehicles
  final vehiclesBox = HiveBoxes.vehiclesBox();
  for (final key in vehiclesBox.keys.toList()) {
    final raw = vehiclesBox.get(key);
    if (raw == null) continue;
    final map = Map<String, dynamic>.from(raw);

    final vehicleId = map['id'] as String? ?? '';
    final savedOdometer = (map['savedOdometerKm'] ?? 0) as int;
    final currentOdometer = (map['currentOdometerKm'] ?? savedOdometer) as int;
    final defaultInterval = (map['defaultIntervalKm'] ?? 5000) as int;
    final timeSuggestion = (map['timeSuggestionMonths'] ?? 6) as int;
    final lastOilDateStr = map['lastOilChangeDate'] as String?;
    final lastOilDate = lastOilDateStr != null ? DateTime.tryParse(lastOilDateStr) : null;

    // Create maintenance items for this vehicle
    for (final t in types) {
      if (t.id == oilType.id) {
        // Oil Change item — use the old vehicle-specific values
        await itemRepo.addForVehicle(
          vehicleId: vehicleId,
          typeId: t.id,
          typeName: t.name,
          intervalKm: defaultInterval,
          intervalMonths: timeSuggestion,
          savedOdometerKm: savedOdometer,
          lastServiceDate: lastOilDate,
        );
      } else {
        // Other types — use defaults, baseline = current odometer
        await itemRepo.addForVehicle(
          vehicleId: vehicleId,
          typeId: t.id,
          typeName: t.name,
          intervalKm: t.defaultIntervalKm,
          intervalMonths: t.defaultIntervalMonths,
          savedOdometerKm: currentOdometer,
        );
      }
    }

    // Re-save vehicle without old fields
    await vehiclesBox.put(key, {
      'id': vehicleId,
      'name': map['name'] ?? '',
      'currentOdometerKm': currentOdometer,
      'photoPath': map['photoPath'],
    });
  }

  // Migrate old oil change records
  final oilChangesBox = HiveBoxes.oilChangesBox();
  for (final key in oilChangesBox.keys.toList()) {
    final raw = oilChangesBox.get(key);
    if (raw == null) continue;
    final map = Map<String, dynamic>.from(raw);

    await recordRepo.add(
      vehicleId: (map['vehicleId'] ?? '') as String,
      typeId: oilType.id,
      typeName: oilType.name,
      odometerKm: (map['odometerKm'] ?? 0) as int,
    );
  }

  await meta.put('v2_migrated', true);
}
