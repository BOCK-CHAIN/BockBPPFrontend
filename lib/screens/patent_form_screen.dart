// lib/screens/patent_form_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scholar/core/pdf_utils.dart';
import '../services/patent_service.dart';

class PatentFormScreen extends StatefulWidget {
  final Map<String, dynamic>? patent;
  const PatentFormScreen({super.key, this.patent});

  @override
  State<PatentFormScreen> createState() => _PatentFormScreenState();
}

class _PatentFormScreenState extends State<PatentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _assigneeCtrl = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _technicalFieldCtrl = TextEditingController();
  final _backgroundCtrl = TextEditingController();
  final _claimsCtrl = TextEditingController();
  final _detailedDescCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  final _newInventorCtrl = TextEditingController();
  final _attorneysCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

  String _status = 'Draft';
  String? _category;
  bool _showCustomCategory = false;
  DateTime? _filingDate;
  DateTime? _publicationDate;
  DateTime? _grantDate;
  DateTime? _validityDate;

  List<dynamic> _allInventors = [];
  List<String> _selectedInventorIds = [];
  List<dynamic> _allPatents = [];
  List<String> _selectedCitedIds = [];

  String? _fileBase64;
  String? _fileName;
  String? _mimeType;
  String? _coverBase64;
  String? _coverName;
  String? _coverMime;
  String? _existingFileUrl;
  String? _existingCoverUrl;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.patent != null;

  static const _statuses = ['Draft', 'Published'];
  static const _categories = [
    'AI / Machine Learning',
    'Mechanical',
    'Electronics',
    'Biotechnology',
    'Chemical',
    'Software',
    'Medical Devices',
    'Energy',
    'Materials',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadPickerData();
    if (_isEdit) _populateForm();
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _assigneeCtrl,
      _abstractCtrl,
      _technicalFieldCtrl,
      _backgroundCtrl,
      _claimsCtrl,
      _detailedDescCtrl,
      _keywordsCtrl,
      _newInventorCtrl,
      _attorneysCtrl,
      _customCategoryCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populateForm() {
    final p = widget.patent!;
    _titleCtrl.text = p['title'] ?? '';
    _assigneeCtrl.text = p['assignee'] ?? '';
    _abstractCtrl.text = p['abstract'] ?? '';
    _technicalFieldCtrl.text = p['technical_field'] ?? '';
    _backgroundCtrl.text = p['background'] ?? '';
    _claimsCtrl.text = p['claims'] ?? '';
    _detailedDescCtrl.text = p['detailed_description'] ?? '';
    _keywordsCtrl.text = ((p['keywords'] as List?) ?? []).join(', ');
    _attorneysCtrl.text = p['attorneys'] ?? '';
    _status = p['status'] ?? 'Draft';
    _existingFileUrl = p['file_url'];
    _existingCoverUrl = p['cover_url'];

    final cat = p['category'] as String?;
    if (cat != null && !_categories.contains(cat)) {
      _category = 'Other';
      _showCustomCategory = true;
      _customCategoryCtrl.text = cat;
    } else {
      _category = cat;
    }

    if (p['filing_date'] != null) {
      _filingDate = DateTime.tryParse(p['filing_date']);
    }
    if (p['publication_date'] != null) {
      _publicationDate = DateTime.tryParse(p['publication_date']);
    }
    if (p['grant_date'] != null) {
      _grantDate = DateTime.tryParse(p['grant_date']);
    }
    if (p['validity_date'] != null) {
      _validityDate = DateTime.tryParse(p['validity_date']);
    }

    _selectedInventorIds = (p['patent_inventors'] as List? ?? [])
        .map((pi) => pi['inventors']?['id'] as String?)
        .whereType<String>()
        .toList();
    _selectedCitedIds = (p['citations_from'] as List? ?? [])
        .map((c) => c['cited_patent']?['id'] as String?)
        .whereType<String>()
        .toList();
  }

  Future<void> _loadPickerData() async {
    setState(() => _loading = true);
    try {
      final inventors = await PatentService.getInventors();
      final patents = await PatentService.getPatents();
      setState(() {
        _allInventors = inventors;
        _allPatents =
            patents.where((p) => p['id'] != widget.patent?['id']).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(String field) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (field == 'filing') _filingDate = picked;
      if (field == 'publication') _publicationDate = picked;
      if (field == 'grant') _grantDate = picked;
      if (field == 'validity') _validityDate = picked;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    String? coverBase64;
    try {
      coverBase64 = await PdfUtils.generatePdfCoverBase64(file.bytes!);
    } catch (_) {
      coverBase64 = null;
    }

    setState(() {
      _fileBase64 = base64Encode(file.bytes!);
      _fileName = file.name;
      _mimeType = 'application/pdf';
      _coverBase64 = coverBase64;
      _coverName = '${file.name.split('.').first}_cover.png';
      _coverMime = 'image/png';
      _existingCoverUrl = null;
    });
  }

  Future<void> _createInventorInline() async {
    final name = _newInventorCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      final inv = await PatentService.createInventor(name);
      setState(() {
        _allInventors.add(inv);
        _selectedInventorIds.add(inv['id']);
        _newInventorCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteInventor(String inventorId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Inventor'),
        content: Text('Delete "$name" from the system? This cannot be undone.'),
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
      await PatentService.deleteInventor(inventorId);
      setState(() {
        _allInventors.removeWhere((inv) => inv['id'] == inventorId);
        _selectedInventorIds.remove(inventorId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String? get _effectiveCategory {
    if (_category == 'Other') {
      final custom = _customCategoryCtrl.text.trim();
      return custom.isNotEmpty ? custom : null;
    }
    return _category;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = PatentPayload(
      title: _titleCtrl.text.trim(),
      status: _status,
      assignee:
          _assigneeCtrl.text.trim().isEmpty ? null : _assigneeCtrl.text.trim(),
      attorneys: _attorneysCtrl.text.trim().isEmpty
          ? null
          : _attorneysCtrl.text.trim(),
      abstract:
          _abstractCtrl.text.trim().isEmpty ? null : _abstractCtrl.text.trim(),
      technicalField: _technicalFieldCtrl.text.trim().isEmpty
          ? null
          : _technicalFieldCtrl.text.trim(),
      background: _backgroundCtrl.text.trim().isEmpty
          ? null
          : _backgroundCtrl.text.trim(),
      claims: _claimsCtrl.text.trim().isEmpty ? null : _claimsCtrl.text.trim(),
      detailedDescription: _detailedDescCtrl.text.trim().isEmpty
          ? null
          : _detailedDescCtrl.text.trim(),
      category: _effectiveCategory,
      keywords: _keywordsCtrl.text.trim().isEmpty
          ? []
          : _keywordsCtrl.text
              .split(',')
              .map((k) => k.trim())
              .where((k) => k.isNotEmpty)
              .toList(),
      filingDate: _filingDate?.toIso8601String().substring(0, 10),
      publicationDate: _publicationDate?.toIso8601String().substring(0, 10),
      grantDate: _grantDate?.toIso8601String().substring(0, 10),
      validityDate: _validityDate?.toIso8601String().substring(0, 10),
      inventorIds: _selectedInventorIds,
      citedPatentIds: _selectedCitedIds,
      fileBase64: _fileBase64,
      fileName: _fileName,
      mimeType: _mimeType,
      coverBase64: _coverBase64,
      coverName: _coverName,
      coverMime: _coverMime,
      existingCoverUrl: _fileBase64 == null ? _existingCoverUrl : null,
      existingFileUrl: _existingFileUrl,
    );
    try {
      if (_isEdit) {
        await PatentService.updatePatent(widget.patent!['id'], payload);
      } else {
        await PatentService.createPatent(payload);
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
    const color = Color(0xFF6C3CE1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF6F4FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28)),
            ),
            child: Row(children: [
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              const Icon(Icons.lightbulb_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(_isEdit ? 'Edit Patent' : 'New Patent',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child:
                        ListView(padding: const EdgeInsets.all(20), children: [
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

                      // ── CORE ───────────────────────────────────────
                      _sectionHeader('Core Information', color),
                      const SizedBox(height: 10),
                      _card(
                          cardBg,
                          color,
                          'Title *',
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: _deco('Patent title'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          )),
                      const SizedBox(height: 12),
                      _card(
                          cardBg,
                          color,
                          'Assignee',
                          TextFormField(
                              controller: _assigneeCtrl,
                              decoration:
                                  _deco('Company or individual owner'))),
                      const SizedBox(height: 12),
                      _card(
                          cardBg,
                          color,
                          'Attorneys',
                          TextFormField(
                              controller: _attorneysCtrl,
                              decoration: _deco('e.g. John Smith, Jane Doe'))),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _card(
                                cardBg,
                                color,
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
                        const SizedBox(width: 12),
                        Expanded(
                            child: _card(
                                cardBg,
                                color,
                                'Category',
                                DropdownButtonFormField<String>(
                                  value: _category,
                                  decoration: _deco('Select'),
                                  dropdownColor: cardBg,
                                  items: _categories
                                      .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c,
                                              style: const TextStyle(
                                                  fontSize: 12))))
                                      .toList(),
                                  onChanged: (v) => setState(() {
                                    _category = v;
                                    _showCustomCategory = v == 'Other';
                                    if (!_showCustomCategory) {
                                      _customCategoryCtrl.clear();
                                    }
                                  }),
                                ))),
                      ]),
                      if (_showCustomCategory) ...[
                        const SizedBox(height: 12),
                        _card(
                            cardBg,
                            color,
                            'Custom Category',
                            TextFormField(
                              controller: _customCategoryCtrl,
                              decoration: _deco('Enter your category...'),
                              validator: (v) => _showCustomCategory &&
                                      (v == null || v.trim().isEmpty)
                                  ? 'Please enter a category'
                                  : null,
                            )),
                      ],
                      const SizedBox(height: 20),

                      // ── DATES ──────────────────────────────────────
                      _sectionHeader('Dates', color),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _card(
                                cardBg,
                                color,
                                'Filing Date',
                                _DatePicker(
                                    value: _filingDate,
                                    hint: 'Select date',
                                    color: color,
                                    onTap: () => _pickDate('filing')))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _card(
                                cardBg,
                                color,
                                'Publication Date',
                                _DatePicker(
                                    value: _publicationDate,
                                    hint: 'Select date',
                                    color: color,
                                    onTap: () => _pickDate('publication')))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _card(
                                cardBg,
                                color,
                                'Grant Date',
                                _DatePicker(
                                    value: _grantDate,
                                    hint: 'Select date',
                                    color: color,
                                    onTap: () => _pickDate('grant')))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _card(
                                cardBg,
                                color,
                                'Validity Date',
                                _DatePicker(
                                    value: _validityDate,
                                    hint: 'Select date',
                                    color: color,
                                    onTap: () => _pickDate('validity')))),
                      ]),
                      const SizedBox(height: 20),

                      // ── CONTENT ────────────────────────────────────
                      _sectionHeader('Patent Content', color),
                      const SizedBox(height: 10),
                      _card(
                          cardBg,
                          color,
                          'Abstract',
                          TextFormField(
                              controller: _abstractCtrl,
                              maxLines: 4,
                              decoration:
                                  _deco('Brief summary of the invention'))),
                      const SizedBox(height: 12),
                      _card(
                          cardBg,
                          color,
                          'Technical Field',
                          TextFormField(
                              controller: _technicalFieldCtrl,
                              maxLines: 2,
                              decoration:
                                  _deco('Domain or area of the invention'))),
                      const SizedBox(height: 12),
                      _card(
                          cardBg,
                          color,
                          'Background / Prior Art',
                          TextFormField(
                              controller: _backgroundCtrl,
                              maxLines: 4,
                              decoration:
                                  _deco('Problem statement and prior art'))),
                      const SizedBox(height: 12),
                      _card(
                          cardBg,
                          color,
                          'Claims *',
                          TextFormField(
                            controller: _claimsCtrl,
                            maxLines: 6,
                            decoration: _deco(
                                'What is legally protected by this patent'),
                          ),
                          accent: Colors.deepOrange,
                          note: 'Most important — defines legal protection'),
                      const SizedBox(height: 12),
                      _card(
                          cardBg,
                          color,
                          'Detailed Description',
                          TextFormField(
                              controller: _detailedDescCtrl,
                              maxLines: 6,
                              decoration: _deco('Full technical description'))),
                      const SizedBox(height: 12),
                      _card(
                          cardBg,
                          color,
                          'Keywords',
                          TextFormField(
                              controller: _keywordsCtrl,
                              decoration: _deco(
                                  'Comma separated: AI, neural network...'))),
                      const SizedBox(height: 20),

                      // ── INVENTORS ──────────────────────────────────
                      _sectionHeader('Inventors', color),
                      const SizedBox(height: 10),
                      _card(
                          cardBg,
                          color,
                          'Select Inventors',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_allInventors.isEmpty)
                                Text('No inventors yet — add one below',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13))
                              else
                                ..._allInventors.map((inv) => Row(
                                      children: [
                                        Expanded(
                                          child: CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: color,
                                            title: Text(inv['name'] ?? ''),
                                            value: _selectedInventorIds
                                                .contains(inv['id']),
                                            onChanged: (v) => setState(() {
                                              if (v == true) {
                                                _selectedInventorIds
                                                    .add(inv['id']);
                                              } else {
                                                _selectedInventorIds
                                                    .remove(inv['id']);
                                              }
                                            }),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _deleteInventor(
                                              inv['id'], inv['name'] ?? ''),
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: Colors.red
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                              const Divider(height: 20),
                              Row(children: [
                                Expanded(
                                    child: TextFormField(
                                        controller: _newInventorCtrl,
                                        decoration:
                                            _deco('New inventor name'))),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: color),
                                  onPressed: _createInventorInline,
                                  child: const Text('Add',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ]),
                            ],
                          )),
                      const SizedBox(height: 20),

                      // ── CITATIONS ──────────────────────────────────
                      _sectionHeader('Citations', color),
                      const SizedBox(height: 10),
                      _card(
                          cardBg,
                          color,
                          'Cites Patents',
                          _allPatents.isEmpty
                              ? Text('No other patents to cite yet',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13))
                              : Column(
                                  children: _allPatents
                                      .map((p) => CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                            activeColor: Colors.blueAccent,
                                            title: Text(p['title'] ?? '',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            subtitle: p['application_number'] !=
                                                    null
                                                ? Text(p['application_number'],
                                                    style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500,
                                                        fontSize: 11))
                                                : null,
                                            value: _selectedCitedIds
                                                .contains(p['id']),
                                            onChanged: (v) => setState(() {
                                              if (v == true) {
                                                _selectedCitedIds.add(p['id']);
                                              } else {
                                                _selectedCitedIds
                                                    .remove(p['id']);
                                              }
                                            }),
                                          ))
                                      .toList())),
                      const SizedBox(height: 20),

                      // ── DOCUMENT ───────────────────────────────────
                      _sectionHeader('Document', color),
                      const SizedBox(height: 10),
                      _card(
                          cardBg,
                          color,
                          'PDF Upload',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_existingFileUrl != null &&
                                  _fileBase64 == null)
                                _fileChip(
                                    'Existing file attached', Colors.green),
                              if (_fileBase64 != null)
                                _fileChip(
                                    _fileName ?? 'File selected', Colors.green),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: color)),
                                onPressed: _pickFile,
                                icon: Icon(Icons.upload_file_rounded,
                                    color: color),
                                label: Text(
                                    _fileBase64 != null
                                        ? 'Change PDF'
                                        : 'Upload PDF',
                                    style: TextStyle(color: color)),
                              ),
                              if (_coverBase64 != null ||
                                  (_existingCoverUrl != null &&
                                      _fileBase64 == null)) ...[
                                const SizedBox(height: 12),
                                Text('Cover preview',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _coverBase64 != null
                                      ? Image.memory(
                                          base64Decode(_coverBase64!),
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          _existingCoverUrl!,
                                          width: double.infinity,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            height: 140,
                                            color: Colors.grey.shade900,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ],
                          )),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_isEdit ? 'Save Changes' : 'Create Patent',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(title,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5)),
      );

  Widget _card(Color cardBg, Color color, String label, Widget child,
      {Color? accent, String? note}) {
    final a = accent ?? color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: a.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                TextStyle(color: a, fontWeight: FontWeight.bold, fontSize: 11)),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text(note,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

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

class _DatePicker extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final Color color;
  final VoidCallback onTap;
  const _DatePicker(
      {required this.value,
      required this.hint,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(Icons.calendar_today_rounded, size: 14, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value != null ? value!.toIso8601String().substring(0, 10) : hint,
            style: TextStyle(
                color: value != null ? null : Colors.grey.shade500,
                fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}
