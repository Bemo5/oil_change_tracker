import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> copyPickedImage(String pickedPath) async {
  try {
    final src = File(pickedPath);
    if (!await src.exists()) return null;

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'oil_change', 'vehicle_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final ext = p.extension(pickedPath).toLowerCase();
    final safeExt = (ext.isEmpty) ? '.jpg' : ext;

    final filename = 'car_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final destPath = p.join(photosDir.path, filename);

    final copied = await src.copy(destPath);
    return copied.path;
  } catch (_) {
    return null;
  }
}
