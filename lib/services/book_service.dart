// lib/services/book_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/session.dart';
import '../core/constants.dart';

class BookService {
  static Future<Map<String, String>> _headers() async {
    final sid = await Session.getSessionId();
    return {
      'Content-Type': 'application/json',
      if (sid != null) 'x-session-id': sid,
    };
  }

  static String get _base => ApiConstants.baseUrl;

  // ── List ───────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getBooks({
    String search = '',
    String? genre,
    int? year,
    String? language,
  }) async {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (genre != null) params['genre'] = genre;
    if (year != null) params['year'] = year.toString();
    if (language != null) params['language'] = language;

    final uri = Uri.parse('$_base/library').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to load books';
    return body['books'] as List;
  }

  // ── Single ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getBook(String id) async {
    final res = await http.get(Uri.parse('$_base/library/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Book not found';
    return body['book'] as Map<String, dynamic>;
  }

  // ── Similar ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getSimilar(
      String genre, String excludeId) async {
    final uri = Uri.parse('$_base/library/similar')
        .replace(queryParameters: {'genre': genre, 'exclude': excludeId});
    final res = await http.get(uri, headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) return [];
    return body['books'] as List;
  }

  // ── Create ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createBook(BookPayload p) async {
    final res = await http.post(
      Uri.parse('$_base/library'),
      headers: await _headers(),
      body: jsonEncode(p.toJson()),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 201) throw body['error'] ?? 'Failed to upload book';
    return body['book'] as Map<String, dynamic>;
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  static Future<void> updateBook(String id, BookPayload p) async {
    final res = await http.put(
      Uri.parse('$_base/library/$id'),
      headers: await _headers(),
      body: jsonEncode(p.toJson()),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to update book';
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  static Future<void> deleteBook(String id) async {
    final res = await http.delete(Uri.parse('$_base/library/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to delete book';
  }
}

// ── Payload ────────────────────────────────────────────────────────────────────
class BookPayload {
  final String title;
  final String author;
  final String genre;
  final String? description;
  final int? year;
  final String? language;
  final String? publisher;
  final int? pages;
  final String? isbn;
  // PDF
  final String? fileBase64;
  final String? fileName;
  final String? mimeType;
  final String? existingFileUrl;
  // Cover image
  final String? coverBase64;
  final String? coverName;
  final String? coverMime;
  final String? existingCoverUrl;

  const BookPayload({
    required this.title,
    required this.author,
    required this.genre,
    this.description,
    this.year,
    this.language,
    this.publisher,
    this.pages,
    this.isbn,
    this.fileBase64,
    this.fileName,
    this.mimeType,
    this.existingFileUrl,
    this.coverBase64,
    this.coverName,
    this.coverMime,
    this.existingCoverUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'genre': genre,
        if (description != null) 'description': description,
        if (year != null) 'year': year,
        if (language != null) 'language': language,
        if (publisher != null) 'publisher': publisher,
        if (pages != null) 'pages': pages,
        if (isbn != null) 'isbn': isbn,
        // PDF
        if (fileBase64 != null) 'file_base64': fileBase64,
        if (fileName != null) 'file_name': fileName,
        if (mimeType != null) 'mime_type': mimeType,
        if (existingFileUrl != null) 'file_url': existingFileUrl,
        // Cover
        if (coverBase64 != null) 'cover_base64': coverBase64,
        if (coverName != null) 'cover_name': coverName,
        if (coverMime != null) 'cover_mime': coverMime,
        if (existingCoverUrl != null) 'cover_url': existingCoverUrl,
      };
}
