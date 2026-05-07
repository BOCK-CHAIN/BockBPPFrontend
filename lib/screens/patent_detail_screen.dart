// lib/screens/patent_detail_screen.dart
import 'package:flutter/material.dart';
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
    final color = Theme.of(context).colorScheme.primary;
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
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
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
                                  Wrap(spacing: 8, runSpacing: 8, children: [
                                    if (_patent!['category'] != null)
                                      _chip(Icons.category_rounded,
                                          _patent!['category'], Colors.purple),
                                    if (_patent!['assignee'] != null)
                                      _chip(Icons.business_rounded,
                                          _patent!['assignee'], Colors.teal),
                                    if (_patent!['filing_date'] != null)
                                      _chip(
                                          Icons.calendar_today_rounded,
                                          'Filed: ${_patent!['filing_date'].toString().substring(0, 10)}',
                                          Colors.blueGrey),
                                    if (_patent!['publication_date'] != null)
                                      _chip(
                                          Icons.publish_rounded,
                                          'Published: ${_patent!['publication_date'].toString().substring(0, 10)}',
                                          Colors.indigo),
                                    if (_patent!['file_url'] != null)
                                      _chip(Icons.picture_as_pdf_rounded,
                                          'PDF attached', Colors.green),
                                  ]),
                                  const SizedBox(height: 20),
                                  _buildInventors(cardBg, color),
                                  const SizedBox(height: 12),
                                  if (_patent!['abstract'] != null)
                                    _section(cardBg, color, 'Abstract',
                                        _patent!['abstract']),
                                  if (_patent!['technical_field'] != null)
                                    _section(cardBg, color, 'Technical Field',
                                        _patent!['technical_field']),
                                  if (_patent!['background'] != null)
                                    _section(
                                        cardBg,
                                        color,
                                        'Background / Prior Art',
                                        _patent!['background']),
                                  if (_patent!['claims'] != null)
                                    _section(cardBg, color, 'Claims',
                                        _patent!['claims'],
                                        accent: Colors.deepOrange),
                                  if (_patent!['detailed_description'] != null)
                                    _section(
                                        cardBg,
                                        color,
                                        'Detailed Description',
                                        _patent!['detailed_description']),
                                  if ((_patent!['keywords'] as List?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                    _sectionLabel('Keywords', color),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: color.withValues(
                                                  alpha: 0.15))),
                                      child: Wrap(
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
                                                        style: TextStyle(
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
                                  _buildCitations(cardBg),
                                  const SizedBox(height: 40),
                                ]),
                          ),
                        ),
                      ]),
      ),
    );
  }

  Widget _buildInventors(Color cardBg, Color color) {
    final inventors = (_patent!['patent_inventors'] as List? ?? [])
        .map((pi) => pi['inventors'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (inventors.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('Inventors', color),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
            children: inventors
                .map((inv) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: Icon(Icons.person_rounded,
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

  Widget _buildCitations(Color cardBg) {
    final cited = (_patent!['citations_from'] as List? ?? [])
        .map((c) => c['cited_patent'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .toList();
    final citedBy = (_patent!['citations_to'] as List? ?? [])
        .map((c) => c['patent'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (cited.isEmpty && citedBy.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (cited.isNotEmpty) ...[
        _sectionLabel('Cites', Colors.blueAccent),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.blueAccent.withValues(alpha: 0.2))),
          child: Column(
              children: cited
                  .map((p) => _citationRow(p, Colors.blueAccent))
                  .toList()),
        ),
        const SizedBox(height: 12),
      ],
      if (citedBy.isNotEmpty) ...[
        _sectionLabel('Cited By', Colors.purple),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.2))),
          child: Column(
              children:
                  citedBy.map((p) => _citationRow(p, Colors.purple)).toList()),
        ),
        const SizedBox(height: 12),
      ],
    ]);
  }

  Widget _citationRow(Map<String, dynamic> p, Color accent) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(Icons.lightbulb_outline_rounded, color: accent, size: 14),
          const SizedBox(width: 8),
          Expanded(
              child: Text(p['title'] ?? '',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _section(Color cardBg, Color color, String label, String? content,
      {Color? accent}) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel(label, color),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (accent ?? color).withValues(alpha: 0.15)),
        ),
        child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _sectionLabel(String label, Color color) => Text(label,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5));

  Widget _chip(IconData icon, String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ]),
      );
}
