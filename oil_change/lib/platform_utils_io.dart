import 'dart:io';
import 'package:flutter/widgets.dart';

bool fileExists(String path) {
  try {
    return File(path).existsSync();
  } catch (_) {
    return false;
  }
}

Widget fileImage(String path, {double? width, double? height, BoxFit? fit, Widget Function()? fallback}) {
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => fallback?.call() ?? const SizedBox.shrink(),
  );
}
