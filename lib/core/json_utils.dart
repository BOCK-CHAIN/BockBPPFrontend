import 'dart:convert';

List<dynamic> parseJsonList(dynamic value) {
  if (value is List) return value;
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    } catch (_) {
      // ignore invalid JSON strings
    }
  }
  return [];
}

List<String> parseStringList(dynamic value) {
  return parseJsonList(value).map((item) => item.toString()).toList();
}
