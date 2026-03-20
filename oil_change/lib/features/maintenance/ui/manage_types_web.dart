import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';

/// Export JSON by triggering a browser download.
Future<void> exportJson(String json) async {
  final bytes = utf8.encode(json);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'maintenance_backup.json')
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Pick a JSON file and return its contents.
Future<String?> pickAndReadJson() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final bytes = result.files.single.bytes;
  if (bytes == null) return null;

  return utf8.decode(bytes);
}
