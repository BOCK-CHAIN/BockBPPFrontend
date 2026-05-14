// lib/screens/patent_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bpp/core/json_utils.dart';
import '../core/session.dart';
import '../services/patent_service.dart';
import 'patent_form_screen.dart';

class PatentDetailScreen extends StatefulWidget {
  final String id;
  const PatentDetailScreen({super.key, required this.id});

  @override
  State<PatentDetailScreen> createState() => _PatentDetailScreenState();
}

class _PatentDetailScreenState extends State<PatentDetailScreen> {
  static const color = Color(0xFF6C3CE1);

  Map<String, dynamic>? _patent;
  bool _loading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await Session.getUserId();
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PatentService.getPatent(widget.id);
      setState(() => _patent = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  bool get _isOwner =>
      _currentUserId != null && _patent?['created_by'] == _currentUserId;

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Patent'),
        content: const Text('Delete this patent? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await PatentService.deletePatent(widget.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'Approved':
        return Colors.green;
      case 'Published':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF6F4FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ]))
                : _patent == null
                    ? const Center(child: Text('Patent not found'))
                    : Column(children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4C1D95), Color(0xFF6C3CE1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Icon(
                                        Icons.arrow_back_ios_rounded,
                                        color: Colors.white,
                                        size: 20),
                                  ),
                                  const Spacer(),
                                  if (_isOwner) ...[
                                    GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    PatentFormScreen(
                                                        patent: _patent)));
                                        _load();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Icon(Icons.edit_rounded,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: _delete,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Icon(Icons.delete_rounded,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(_patent!['status'])
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_patent!['status'] ?? 'Draft',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 8),
                                Text(_patent!['title'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                if (_patent!['application_number'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(_patent!['application_number'],
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              ]),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  // ── Top chips ──────────────────────────
                                  Wrap(spacing: 8, runSpacing: 8, children: [
                                    if (_patent!['category'] != null)
                                      _chip(Icons.category_rounded,
                                          _patent!['category']),
                                    if (_patent!['assignee'] != null)
                                      _chip(Icons.business_rounded,
                                          _patent!['assignee']),
                                    if (_patent!['filing_date'] != null)
                                      _chip(Icons.calendar_today_rounded,
                                          'Filed: ${_patent!['filing_date'].toString().substring(0, 10)}'),
                                    if (_patent!['publication_date'] != null)
                                      _chip(Icons.publish_rounded,
                                          'Published: ${_patent!['publication_date'].toString().substring(0, 10)}'),
                                    if (_patent!['file_url'] != null)
                                      _chip(Icons.picture_as_pdf_rounded,
                                          'PDF attached'),
                                  ]),
                                  const SizedBox(height: 20),

                                  // ── Inventors ──────────────────────────
                                  _buildInventors(cardBg),

                                  // ── Content sections ───────────────────
                                  if (_patent!['abstract'] != null)
                                    _textSection(
                                        cardBg,
                                        'Abstract',
                                        Icons.short_text_rounded,
                                        _patent!['abstract']),
                                  if (_patent!['technical_field'] != null)
                                    _textSection(
                                        cardBg,
                                        'Technical Field',
                                        Icons.precision_manufacturing_rounded,
                                        _patent!['technical_field']),
                                  if (_patent!['background'] != null)
                                    _textSection(
                                        cardBg,
                                        'Background / Prior Art',
                                        Icons.history_edu_rounded,
                                        _patent!['background']),
                                  if (_patent!['claims'] != null)
                                    _textSection(
                                        cardBg,
                                        'Claims',
                                        Icons.gavel_rounded,
                                        _patent!['claims']),
                                  if (_patent!['detailed_description'] != null)
                                    _textSection(
                                        cardBg,
                                        'Detailed Description',
                                        Icons.article_rounded,
                                        _patent!['detailed_description']),

                                  // ── Keywords ───────────────────────────
                                  if ((_patent!['keywords'] as List?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                    _sectionCard(
                                      cardBg,
                                      'Keywords',
                                      Icons.tag_rounded,
                                      Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: (_patent!['keywords']
                                                  as List)
                                              .map((k) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                        color: color.withValues(
                                                            alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20)),
                                                    child: Text(k.toString(),
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color: color,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                  ))
                                              .toList()),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // ── Citations ──────────────────────────
                                  _buildCitations(cardBg),

                                  // ── Document (Scholar style) ───────────
                                  if (_patent!['file_url'] != null) ...[
                                    _sectionCard(
                                      cardBg,
                                      'Document',
                                      Icons.picture_as_pdf_rounded,
                                      GestureDetector(
                                        onTap: () =>
                                            _openFile(_patent!['file_url']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: color.withValues(
                                                    alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.download_rounded,
                                                  color: color, size: 18),
                                              SizedBox(width: 8),
                                              Text('Download PDF',
                                                  style: TextStyle(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 40),
                                ]),
                          ),
                        ),
                      ]),
      ),
    );
  }

  // ── Inventors ───────────────────────────────────────────────────────────────
  Widget _buildInventors(Color cardBg) {
    final inventors = parseJsonList(_patent!['patent_inventors'])
        .map((pi) => pi['inventors'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (inventors.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionCard(
        cardBg,
        'Inventors',
        Icons.people_rounded,
        Column(
            children: inventors
                .map((inv) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded,
                              color: color, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Text(inv['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                      ]),
                    ))
                .toList()),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // ── Citations ───────────────────────────────────────────────────────────────
  Widget _buildCitations(Color cardBg) {
    final cited = parseJsonList(_patent!['citations_from'])
        .map((c) => c['cited_patent'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .toList();
    final citedBy = parseJsonList(_patent!['citations_to'])
        .map((c) => c['patent'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (cited.isEmpty && citedBy.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (cited.isNotEmpty) ...[
        _sectionCard(
          cardBg,
          'Cites (${cited.length})',
          Icons.format_list_numbered_rounded,
          Column(children: cited.map((p) => _citationRow(p)).toList()),
        ),
        const SizedBox(height: 12),
      ],
      if (citedBy.isNotEmpty) ...[
        _sectionCard(
          cardBg,
          'Cited By (${citedBy.length})',
          Icons.call_received_rounded,
          Column(children: citedBy.map((p) => _citationRow(p)).toList()),
        ),
        const SizedBox(height: 12),
      ],
    ]);
  }

  Widget _citationRow(Map<String, dynamic> p) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          const Icon(Icons.lightbulb_outline_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
              child: Text(p['title'] ?? '',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
      );

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Text content section — wraps plain text in a _sectionCard
  Widget _textSection(
      Color cardBg, String label, IconData icon, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionCard(
        cardBg,
        label,
        icon,
        Text(content,
            style: TextStyle(
                fontSize: 14, height: 1.5, color: Colors.grey.shade400)),
      ),
      const SizedBox(height: 12),
    ]);
  }

  /// Scholar-style section card with icon + title header
  Widget _sectionCard(Color cardBg, String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}
