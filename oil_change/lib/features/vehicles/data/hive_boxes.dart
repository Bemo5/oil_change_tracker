import 'package:hive/hive.dart';

class HiveBoxes {
  static const vehicles = 'vehicles_box';
  static const oilChanges = 'oil_changes_box';
  static const maintenanceTypes = 'maintenance_types_box';
  static const maintenanceItems = 'maintenance_items_box';
  static const maintenanceRecords = 'maintenance_records_box';
  static const meta = 'meta_box';

  static Future<void> init() async {
    await Hive.openBox<Map>(vehicles);
    await Hive.openBox<Map>(oilChanges);
    await Hive.openBox<Map>(maintenanceTypes);
    await Hive.openBox<Map>(maintenanceItems);
    await Hive.openBox<Map>(maintenanceRecords);
    await Hive.openBox(meta);
  }

  static Box<Map> vehiclesBox() => Hive.box<Map>(vehicles);
  static Box<Map> oilChangesBox() => Hive.box<Map>(oilChanges);
  static Box<Map> maintenanceTypesBox() => Hive.box<Map>(maintenanceTypes);
  static Box<Map> maintenanceItemsBox() => Hive.box<Map>(maintenanceItems);
  static Box<Map> maintenanceRecordsBox() => Hive.box<Map>(maintenanceRecords);
  static Box metaBox() => Hive.box(meta);
}
