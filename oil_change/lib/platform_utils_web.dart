import 'dart:convert';
import 'package:flutter/widgets.dart';

bool fileExists(String path) {
  // On web, photos are stored as data: URIs
  return path.startsWith('data:');
}

Widget fileImage(String path, {double? width, double? height, BoxFit? fit, Widget Function()? fallback}) {
  if (path.startsWith('data:')) {
    try {
      final dataUri = Uri.parse(path);
      final bytes = base64Decode(dataUri.data!.contentAsBytes().toString() != ''
          ? path.split(',').last
          : '');
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback?.call() ?? const SizedBox.shrink(),
      );
    } catch (_) {
      return fallback?.call() ?? const SizedBox.shrink();
    }
  }
  return fallback?.call() ?? const SizedBox.shrink();
}
