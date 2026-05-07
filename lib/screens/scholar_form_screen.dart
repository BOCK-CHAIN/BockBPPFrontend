// lib/screens/scholar_form_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/scholar_service.dart';

class ScholarFormScreen extends StatefulWidget {
  final Map<String, dynamic>? paper;
  const ScholarFormScreen({super.key, this.paper});

  @override
  State<ScholarFormScreen> createState() => _ScholarFormScreenState();
}

class _ScholarFormScreenState extends State<ScholarFormScreen> {
  static const color = Color(0xFF00BCD4);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorsCtrl = TextEditingController(); // comma-separated
  final _abstractCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  final _doiCtrl = TextEditingController();
  final _issnCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _advisorCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  String _status = 'Draft';
  String? _venueType;
  String? _degree;

  List<dynamic> _allPapers = [];
  List<String> _selectedRefIds = [];

  String? _fileBase64;
  String? _fileName;
  String? _mimeType;
  String? _existingFileUrl;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.paper != null;

  static const _venueTypes = [
    'Journal',
    'Conference',
    'Thesis',
    'Preprint',
    'Workshop'
  ];
  static const _degrees = ['B.Tech', 'M.Tech', 'MS', 'PhD'];
  static const _statuses = ['Draft', 'Published'];

  @override
  void initState() {
    super.initState();
    _loadPapers();
    if (_isEdit) _populateForm();
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _authorsCtrl,
      _abstractCtrl,
      _venueCtrl,
      _volumeCtrl,
      _issueCtrl,
      _pagesCtrl,
      _doiCtrl,
      _issnCtrl,
      _isbnCtrl,
      _keywordsCtrl,
      _institutionCtrl,
      _departmentCtrl,
      _advisorCtrl,
      _yearCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populateForm() {
    final p = widget.paper!;
    _titleCtrl.text = p['title'] ?? '';
    _authorsCtrl.text = ((p['authors'] as List?) ?? []).join(', ');
    _abstractCtrl.text = p['abstract'] ?? '';
    _venueCtrl.text = p['venue'] ?? '';
    _volumeCtrl.text = p['volume'] ?? '';
    _issueCtrl.text = p['issue'] ?? '';
    _pagesCtrl.text = p['pages'] ?? '';
    _doiCtrl.text = p['doi'] ?? '';
    _issnCtrl.text = p['issn'] ?? '';
    _isbnCtrl.text = p['isbn'] ?? '';
    _keywordsCtrl.text = ((p['keywords'] as List?) ?? []).join(', ');
    _institutionCtrl.text = p['institution'] ?? '';
    _departmentCtrl.text = p['department'] ?? '';
    _advisorCtrl.text = p['advisor'] ?? '';
    _yearCtrl.text = p['year']?.toString() ?? '';
    _status = p['status'] ?? 'Draft';
    _venueType = p['venue_type'];
    _degree = p['degree'];
    _existingFileUrl = p['file_url'];

    _selectedRefIds = (p['references_made'] as List? ?? [])
        .map((r) => r['cited_paper']?['id'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<void> _loadPapers() async {
    setState(() => _loading = true);
    try {
      final papers = await ScholarService.getPapers();
      setState(() {
        _allPapers =
            papers.where((p) => p['id'] != widget.paper?['id']).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _fileBase64 = base64Encode(file.bytes!);
      _fileName = file.name;
      _mimeType = 'application/pdf';
    });
  }

  List<String> _parseList(String raw) =>
      raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = ScholarPayload(
      title: _titleCtrl.text.trim(),
      authors: _parseList(_authorsCtrl.text),
      status: _status,
      abstract:
          _abstractCtrl.text.trim().isEmpty ? null : _abstractCtrl.text.trim(),
      year: _yearCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_yearCtrl.text.trim()),
      venue: _venueCtrl.text.trim().isEmpty ? null : _venueCtrl.text.trim(),
      venueType: _venueType,
      volume: _volumeCtrl.text.trim().isEmpty ? null : _volumeCtrl.text.trim(),
      issue: _issueCtrl.text.trim().isEmpty ? null : _issueCtrl.text.trim(),
      pages: _pagesCtrl.text.trim().isEmpty ? null : _pagesCtrl.text.trim(),
      doi: _doiCtrl.text.trim().isEmpty ? null : _doiCtrl.text.trim(),
      issn: _issnCtrl.text.trim().isEmpty ? null : _issnCtrl.text.trim(),
      isbn: _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
      keywords: _parseList(_keywordsCtrl.text),
      institution: _institutionCtrl.text.trim().isEmpty
          ? null
          : _institutionCtrl.text.trim(),
      department: _departmentCtrl.text.trim().isEmpty
          ? null
          : _departmentCtrl.text.trim(),
      advisor:
          _advisorCtrl.text.trim().isEmpty ? null : _advisorCtrl.text.trim(),
      degree: _degree,
      citedPaperIds: _selectedRefIds,
      fileBase64: _fileBase64,
      fileName: _fileName,
      mimeType: _mimeType,
      existingFileUrl: _existingFileUrl,
    );

    try {
      if (_isEdit) {
        await ScholarService.updatePaper(widget.paper!['id'], payload);
      } else {
        await ScholarService.createPaper(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0FAFF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.science_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(_isEdit ? 'Edit Paper' : 'New Paper',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                            ),

                          // ── CORE ──────────────────────────────────────────
                          _sectionHeader('Core Information'),
                          const SizedBox(height: 10),

                          _card(
                              cardBg,
                              'Title *',
                              TextFormField(
                                controller: _titleCtrl,
                                decoration: _deco('Paper title'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              )),
                          const SizedBox(height: 12),

                          _card(
                              cardBg,
                              'Authors * (comma separated)',
                              TextFormField(
                                controller: _authorsCtrl,
                                decoration: _deco(
                                    'e.g. enter AuthorName1, enter AuthorName2'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              )),
                          const SizedBox(height: 12),

                          Row(children: [
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Year',
                                    TextFormField(
                                      controller: _yearCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _deco('e.g. 2024'),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Status',
                                    DropdownButtonFormField<String>(
                                      value: _status,
                                      decoration: _deco(null),
                                      dropdownColor: cardBg,
                                      items: _statuses
                                          .map((s) => DropdownMenuItem(
                                              value: s, child: Text(s)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _status = v!),
                                    ))),
                          ]),
                          const SizedBox(height: 20),

                          // ── VENUE ─────────────────────────────────────────
                          _sectionHeader('Publication Venue'),
                          const SizedBox(height: 10),

                          Row(children: [
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Venue Type',
                                    DropdownButtonFormField<String>(
                                      value: _venueType,
                                      decoration: _deco('Select'),
                                      dropdownColor: cardBg,
                                      items: _venueTypes
                                          .map((t) => DropdownMenuItem(
                                              value: t, child: Text(t)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _venueType = v),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Venue Name',
                                    TextFormField(
                                      controller: _venueCtrl,
                                      decoration:
                                          _deco('Journal or Conference'),
                                    ))),
                          ]),
                          const SizedBox(height: 12),

                          Row(children: [
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Volume',
                                    TextFormField(
                                      controller: _volumeCtrl,
                                      decoration: _deco('e.g. 10'),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Issue',
                                    TextFormField(
                                      controller: _issueCtrl,
                                      decoration: _deco('e.g. 3'),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Pages',
                                    TextFormField(
                                      controller: _pagesCtrl,
                                      decoration: _deco('e.g. 12-25'),
                                    ))),
                          ]),
                          const SizedBox(height: 12),

                          Row(children: [
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'DOI',
                                    TextFormField(
                                      controller: _doiCtrl,
                                      decoration: _deco('10.xxxx/xxxxx'),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'ISSN',
                                    TextFormField(
                                      controller: _issnCtrl,
                                      decoration: _deco('xxxx-xxxx'),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'ISBN',
                                    TextFormField(
                                      controller: _isbnCtrl,
                                      decoration: _deco('Optional'),
                                    ))),
                          ]),
                          const SizedBox(height: 20),

                          // ── CONTENT ───────────────────────────────────────
                          _sectionHeader('Content'),
                          const SizedBox(height: 10),

                          _card(
                              cardBg,
                              'Abstract',
                              TextFormField(
                                controller: _abstractCtrl,
                                maxLines: 5,
                                decoration: _deco('Brief summary of the paper'),
                              )),
                          const SizedBox(height: 12),

                          _card(
                              cardBg,
                              'Keywords (comma separated)',
                              TextFormField(
                                controller: _keywordsCtrl,
                                decoration: _deco(
                                    'e.g. deep learning, NLP, transformer'),
                              )),
                          const SizedBox(height: 20),

                          // ── INSTITUTION (IIIT style) ───────────────────────
                          _sectionHeader('Institution / IIIT Details'),
                          const SizedBox(height: 10),

                          Row(children: [
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Institution',
                                    TextFormField(
                                      controller: _institutionCtrl,
                                      decoration: _deco('e.g. IIIT Hyderabad'),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Department',
                                    TextFormField(
                                      controller: _departmentCtrl,
                                      decoration: _deco('e.g. CSE, ECE'),
                                    ))),
                          ]),
                          const SizedBox(height: 12),

                          Row(children: [
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Advisor / Supervisor',
                                    TextFormField(
                                      controller: _advisorCtrl,
                                      decoration: _deco('Prof. Name'),
                                    ))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _card(
                                    cardBg,
                                    'Degree',
                                    DropdownButtonFormField<String>(
                                      value: _degree,
                                      decoration: _deco('Select'),
                                      dropdownColor: cardBg,
                                      items: _degrees
                                          .map((d) => DropdownMenuItem(
                                              value: d, child: Text(d)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _degree = v),
                                    ))),
                          ]),
                          const SizedBox(height: 20),

                          // ── REFERENCES ────────────────────────────────────
                          _sectionHeader('References (cites other papers)'),
                          const SizedBox(height: 10),

                          _card(
                              cardBg,
                              'Select Referenced Papers',
                              _allPapers.isEmpty
                                  ? Text('No other papers yet',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13))
                                  : Column(
                                      children: _allPapers.map((p) {
                                        final authors =
                                            (p['authors'] as List? ?? [])
                                                .cast<String>();
                                        return CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          activeColor: color,
                                          title: Text(p['title'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                          subtitle: Text(
                                            [
                                              if (authors.isNotEmpty)
                                                authors.first,
                                              if (p['year'] != null)
                                                p['year'].toString(),
                                            ].join(' · '),
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11),
                                          ),
                                          value:
                                              _selectedRefIds.contains(p['id']),
                                          onChanged: (v) => setState(() {
                                            if (v == true) {
                                              _selectedRefIds.add(p['id']);
                                            } else {
                                              _selectedRefIds.remove(p['id']);
                                            }
                                          }),
                                        );
                                      }).toList(),
                                    )),
                          const SizedBox(height: 20),

                          // ── FILE ──────────────────────────────────────────
                          _sectionHeader('Document'),
                          const SizedBox(height: 10),

                          _card(
                              cardBg,
                              'PDF Upload',
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_existingFileUrl != null &&
                                      _fileBase64 == null)
                                    _fileChip(
                                        'Existing file attached', Colors.green),
                                  if (_fileBase64 != null)
                                    _fileChip(_fileName ?? 'File selected',
                                        Colors.green),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: color)),
                                    onPressed: _pickFile,
                                    icon: const Icon(Icons.upload_file_rounded,
                                        color: color),
                                    label: Text(
                                      _fileBase64 != null
                                          ? 'Change PDF'
                                          : 'Upload PDF',
                                      style: const TextStyle(color: color),
                                    ),
                                  ),
                                ],
                              )),
                          const SizedBox(height: 28),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _saving ? null : _submit,
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      _isEdit ? 'Save Changes' : 'Create Paper',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5)),
      );

  Widget _card(Color cardBg, String label, Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _fileChip(String label, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(Icons.check_circle_rounded, color: c, size: 14),
          const SizedBox(width: 6),
          Expanded(
              child: Text(label,
                  style: TextStyle(color: c, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
        ]),
      );

  InputDecoration _deco(String? hint) => InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        isDense: true,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      );
}
