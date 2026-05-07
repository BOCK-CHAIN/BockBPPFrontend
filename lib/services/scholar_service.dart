// lib/services/scholar_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/session.dart';

const String _base = 'http://localhost:3000';

class ScholarService {
  static Future<Map<String, String>> _headers() async {
    final sid = await Session.getSessionId();
    return {
      'Content-Type': 'application/json',
      if (sid != null) 'x-session-id': sid,
    };
  }

  static Future<List<dynamic>> getPapers({
    String search = '',
    String? venueType,
    int? year,
    String? status,
  }) async {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (venueType != null) params['venue_type'] = venueType;
    if (year != null) params['year'] = year.toString();
    if (status != null) params['status'] = status;

    final uri = Uri.parse('$_base/scholar').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to load papers';
    return body['papers'] as List;
  }

  static Future<Map<String, dynamic>> getPaper(String id) async {
    final res = await http.get(Uri.parse('$_base/scholar/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Paper not found';
    return body['paper'] as Map<String, dynamic>;
  }

  static Future<void> createPaper(ScholarPayload p) async {
    final res = await http.post(
      Uri.parse('$_base/scholar'),
      headers: await _headers(),
      body: jsonEncode(p.toJson()),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 201) throw body['error'] ?? 'Failed to create paper';
  }

  static Future<void> updatePaper(String id, ScholarPayload p) async {
    final res = await http.put(
      Uri.parse('$_base/scholar/$id'),
      headers: await _headers(),
      body: jsonEncode(p.toJson()),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to update paper';
  }

  static Future<void> deletePaper(String id) async {
    final res = await http.delete(Uri.parse('$_base/scholar/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to delete paper';
  }

  static Future<Map<String, dynamic>> getAuthorPapers(String name) async {
    final uri = Uri.parse('$_base/scholar/author/${Uri.encodeComponent(name)}');
    final res = await http.get(uri, headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200)
      throw body['error'] ?? 'Failed to load author papers';
    return body as Map<String, dynamic>;
  }
}

// ── Payload model ─────────────────────────────────────────────────────────────
class ScholarPayload {
  final String title;
  final String status;
  final List<String> authors;
  final String? abstract;
  final int? year;
  final String? venue;
  final String? venueType;
  final String? volume;
  final String? issue;
  final String? pages;
  final String? doi;
  final String? issn;
  final String? isbn;
  final List<String> keywords;
  final String? institution;
  final String? department;
  final String? advisor;
  final String? degree;
  final List<String> citedPaperIds;
  final String? fileBase64;
  final String? fileName;
  final String? mimeType;
  final String? existingFileUrl;

  const ScholarPayload({
    required this.title,
    required this.authors,
    this.status = 'Draft',
    this.abstract,
    this.year,
    this.venue,
    this.venueType,
    this.volume,
    this.issue,
    this.pages,
    this.doi,
    this.issn,
    this.isbn,
    this.keywords = const [],
    this.institution,
    this.department,
    this.advisor,
    this.degree,
    this.citedPaperIds = const [],
    this.fileBase64,
    this.fileName,
    this.mimeType,
    this.existingFileUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'authors': authors,
        'status': status,
        if (abstract != null) 'abstract': abstract,
        if (year != null) 'year': year,
        if (venue != null) 'venue': venue,
        if (venueType != null) 'venue_type': venueType,
        if (volume != null) 'volume': volume,
        if (issue != null) 'issue': issue,
        if (pages != null) 'pages': pages,
        if (doi != null) 'doi': doi,
        if (issn != null) 'issn': issn,
        if (isbn != null) 'isbn': isbn,
        'keywords': keywords,
        if (institution != null) 'institution': institution,
        if (department != null) 'department': department,
        if (advisor != null) 'advisor': advisor,
        if (degree != null) 'degree': degree,
        'cited_paper_ids': citedPaperIds,
        if (fileBase64 != null) 'file_base64': fileBase64,
        if (fileName != null) 'file_name': fileName,
        if (mimeType != null) 'mime_type': mimeType,
        if (existingFileUrl != null) 'file_url': existingFileUrl,
      };
}
