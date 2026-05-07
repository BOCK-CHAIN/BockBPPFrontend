// lib/services/auth_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AuthService {
  // Generate hex ID from all registration fields (your exact spec)
  static String generateHexId({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dob,
    required String gender,
  }) {
    final input = email + password + firstName + lastName + dob + gender;
    final bytes = utf8.encode(input);
    final digest = sha512.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Register — returns hex_id on success so UI can show it
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dob,
    required String gender,
  }) async {
    final hexId = generateHexId(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      dob: dob,
      gender: gender,
    );

    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'dob': dob,
        'gender': gender,
        'hex_id': hexId,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201) {
      // Return hex_id so the UI can show it in the popup
      return {'success': true, 'data': body, 'hex_id': hexId};
    } else {
      return {
        'success': false,
        'error': body['error'] ?? 'Registration failed'
      };
    }
  }

  // Login — uses hex ID + password
  static Future<Map<String, dynamic>> login({
    required String hexId,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'hex_id': hexId, 'password': password}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'data': body};
    } else {
      return {'success': false, 'error': body['error'] ?? 'Login failed'};
    }
  }

  // Logout
  static Future<void> logout(String sessionId) async {
    await http.post(
      Uri.parse(ApiConstants.logout),
      headers: {'x-session-id': sessionId},
    );
  }
}
