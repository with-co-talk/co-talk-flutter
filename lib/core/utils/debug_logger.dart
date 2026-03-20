import 'package:flutter/foundation.dart';

mixin DebugLogger {
  String get logTag => runtimeType.toString();

  void log(String message) {
    if (kDebugMode) {
      debugPrint('[$logTag] $message');
    }
  }
}
