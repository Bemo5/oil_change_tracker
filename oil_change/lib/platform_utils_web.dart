import 'package:flutter/widgets.dart';

bool fileExists(String path) => false;

Widget fileImage(String path, {double? width, double? height, BoxFit? fit, Widget Function()? fallback}) {
  return fallback?.call() ?? const SizedBox.shrink();
}
