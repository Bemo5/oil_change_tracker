import 'package:hive/hive.dart';

class HiveBoxes {
  static const vehicles = 'vehicles_box';

  static Future<void> init() async {
    await Hive.openBox<Map>(vehicles);
  }

  static Box<Map> vehiclesBox() {
    return Hive.box<Map>(vehicles);
  }
}
