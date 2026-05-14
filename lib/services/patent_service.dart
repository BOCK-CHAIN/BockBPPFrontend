// lib/services/patent_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/session.dart';

const String _base = 'http://localhost:3000';

class PatentService {
  static Future<Map<String, String>> _headers() async {
    final sid = await Session.getSessionId();
    return {
      'Content-Type': 'application/json',
      if (sid != null) 'x-session-id': sid,
    };
  }

  static Future<List<dynamic>> getPatents({
    String search = '',
    String? status,
    String? category,
  }) async {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status;
    if (category != null) params['category'] = category;
    final uri = Uri.parse('$_base/patents').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to load patents';
    return body['patents'] as List;
  }

  static Future<Map<String, dynamic>> getPatent(String id) async {
    final res = await http.get(Uri.parse('$_base/patents/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Patent not found';
    return body['patent'] as Map<String, dynamic>;
  }

  static Future<void> createPatent(PatentPayload p) async {
    final res = await http.post(
      Uri.parse('$_base/patents'),
      headers: await _headers(),
      body: jsonEncode(p.toJson()),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 201) throw body['error'] ?? 'Failed to create patent';
  }

  static Future<void> updatePatent(String id, PatentPayload p) async {
    final res = await http.put(
      Uri.parse('$_base/patents/$id'),
      headers: await _headers(),
      body: jsonEncode(p.toJson()),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to update patent';
  }

  static Future<void> deletePatent(String id) async {
    final res = await http.delete(Uri.parse('$_base/patents/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Failed to delete patent';
  }

  static Future<List<dynamic>> getInventors({String search = ''}) async {
    final uri = Uri.parse('$_base/inventors').replace(
      queryParameters: search.isNotEmpty ? {'search': search} : {},
    );
    final res = await http.get(uri, headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw body['error'] ?? 'Failed to load inventors';
    }
    return body['inventors'] as List;
  }

  static Future<Map<String, dynamic>> getInventor(String id) async {
    final res = await http.get(Uri.parse('$_base/inventors/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw body['error'] ?? 'Inventor not found';
    return body as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createInventor(String name) async {
    final res = await http.post(
      Uri.parse('$_base/inventors'),
      headers: await _headers(),
      body: jsonEncode({'name': name}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw body['error'] ?? 'Failed to create inventor';
    }
    return body['inventor'] as Map<String, dynamic>;
  }

  static Future<void> deleteInventor(String id) async {
    final res = await http.delete(Uri.parse('$_base/inventors/$id'),
        headers: await _headers());
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw body['error'] ?? 'Failed to delete inventor';
    }
  }
}

class PatentPayload {
  final String title;
  final String status;
  final String? filingDate;
  final String? publicationDate;
  final String? grantDate;
  final String? validityDate;
  final String? assignee;
  final String? attorneys;
  final String? abstract;
  final String? technicalField;
  final String? background;
  final String? claims;
  final String? detailedDescription;
  final String? category;
  final List<String> keywords;
  final List<String> inventorIds;
  final List<String> citedPatentIds;
  final String? fileBase64;
  final String? fileName;
  final String? mimeType;
  final String? coverBase64;
  final String? coverName;
  final String? coverMime;
  final String? existingFileUrl;
  final String? existingCoverUrl;

  const PatentPayload({
    required this.title,
    this.status = 'Draft',
    this.filingDate,
    this.publicationDate,
    this.grantDate,
    this.validityDate,
    this.assignee,
    this.attorneys,
    this.abstract,
    this.technicalField,
    this.background,
    this.claims,
    this.detailedDescription,
    this.category,
    this.keywords = const [],
    this.inventorIds = const [],
    this.citedPatentIds = const [],
    this.fileBase64,
    this.fileName,
    this.mimeType,
    this.coverBase64,
    this.coverName,
    this.coverMime,
    this.existingFileUrl,
    this.existingCoverUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'status': status,
        if (filingDate != null) 'filing_date': filingDate,
        if (publicationDate != null) 'publication_date': publicationDate,
        if (grantDate != null) 'grant_date': grantDate,
        if (validityDate != null) 'validity_date': validityDate,
        if (assignee != null) 'assignee': assignee,
        if (attorneys != null) 'attorneys': attorneys,
        if (abstract != null) 'abstract': abstract,
        if (technicalField != null) 'technical_field': technicalField,
        if (background != null) 'background': background,
        if (claims != null) 'claims': claims,
        if (detailedDescription != null)
          'detailed_description': detailedDescription,
        if (category != null) 'category': category,
        'keywords': keywords,
        'inventor_ids': inventorIds,
        'cited_patent_ids': citedPatentIds,
        if (fileBase64 != null) 'file_base64': fileBase64,
        if (fileName != null) 'file_name': fileName,
        if (mimeType != null) 'mime_type': mimeType,
        if (coverBase64 != null) 'cover_base64': coverBase64,
        if (coverName != null) 'cover_name': coverName,
        if (coverMime != null) 'cover_mime': coverMime,
        if (existingCoverUrl != null) 'cover_url': existingCoverUrl,
        if (existingFileUrl != null) 'file_url': existingFileUrl,
      };
}
