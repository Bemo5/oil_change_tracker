import 'dart:convert';
import 'package:file_picker/file_picker.dart';

Future<String?> copyPickedImage(String pickedPath) async => null;

/// Pick image on web and return as data: URI string
Future<String?> pickImageAsDataUri() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );

  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  if (file.bytes == null) return null;

  final ext = file.extension?.toLowerCase() ?? 'png';
  final mime = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'image/$ext';
  return 'data:$mime;base64,${base64Encode(file.bytes!)}';
}
