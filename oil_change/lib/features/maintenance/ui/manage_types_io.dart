import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Export JSON by letting user pick a save location.
Future<void> exportJson(String json) async {
  final savePath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save backup',
    fileName: 'maintenance_backup.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (savePath == null) return;
  await File(savePath).writeAsString(json);
}

/// Clipboard stubs for non-web (not used).
Future<void> exportToClipboard(String json) async {}
Future<String?> importFromClipboard() async => null;

/// Pick a JSON file and return its contents.
Future<String?> pickAndReadJson() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;

  final filePath = result.files.single.path;
  if (filePath == null) return null;

  return File(filePath).readAsString();
}
