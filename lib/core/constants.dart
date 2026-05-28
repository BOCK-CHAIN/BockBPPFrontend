// lib/core/constants.dart
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
}

// ── Share link helpers ────────────────────────────────────────────────────────
class ShareConstants {
  static String get appBase {
    if (kIsWeb) {
      final uri = Uri.base;
      return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    }
    // Mobile deep-link placeholder – update to your deployed URL when ready
    return 'http://localhost:62458';
  }

  static String bookLink(String id) => '$appBase/#/books?id=$id';
  static String scholarLink(String id) => '$appBase/#/scholar?id=$id';
  static String patentLink(String id) => '$appBase/#/patents?id=$id';
}
