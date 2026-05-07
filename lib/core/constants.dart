// lib/core/constants.dart
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      // Web browser - backend running on same machine
      return 'http://localhost:3000';
    } else {
      // Android emulator
      return 'http://10.0.2.2:3000';
      // For physical phone, replace with your PC's local IP e.g:
      // return 'http://192.168.1.5:3000';
    }
  }

  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
}
