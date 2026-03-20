import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'l10n.dart';
import 'features/vehicles/data/hive_boxes.dart';
import 'features/maintenance/data/maintenance_type_repo.dart';
import 'migration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await HiveBoxes.init();

  // Migrate old data and seed defaults
  await migrateV1ToV2();
  await MaintenanceTypeRepo().seedDefaults();

  S.init();

  runApp(const MaintenanceApp());
}
