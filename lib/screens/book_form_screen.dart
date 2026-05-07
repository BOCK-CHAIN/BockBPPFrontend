// lib/screens/book_form_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/book_service.dart';

class BookFormScreen extends StatefulWidget {
  final Map<String, dynamic>? book;
  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  static const _purple = Color(0xFF6C3CE1);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _publisherCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  String _genre = 'Fiction';
  String _language = 'English';
  bool _saving = false;
  String? _error;

  // PDF
  String? _fileBase64;
  String? _fileName;
  String? _existingFileUrl;

  // Cover image
  String? _coverBase64;
  String? _coverName;
  String? _coverMime;
  String? _existingCoverUrl;

  bool get _isEdit => widget.book != null;

  static const _genres = [
    'Fiction',
    'Non-Fiction',
    'Science',
    'Technology',
    'History',
    'Biography',
    'Philosophy',
    'Mathematics',
    'Medicine',
    'Law',
    'Arts',
    'Other',
  ];
  static const _languages = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Arabic',
    'Portuguese',
    'Russian',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) _populate();
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _authorCtrl,
      _descCtrl,
      _publisherCtrl,
      _isbnCtrl,
      _pagesCtrl,
      _yearCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _populate() {
    final b = widget.book!;
    _titleCtrl.text = b['title'] ?? '';
    _authorCtrl.text = b['author'] ?? '';
    _descCtrl.text = b['description'] ?? '';
    _publisherCtrl.text = b['publisher'] ?? '';
    _isbnCtrl.text = b['isbn'] ?? '';
    _pagesCtrl.text = b['pages']?.toString() ?? '';
    _yearCtrl.text = b['year']?.toString() ?? '';
    _genre = b['genre'] ?? 'Fiction';
    _language = b['language'] ?? 'English';
    _existingFileUrl = b['file_url'];
    _existingCoverUrl = b['cover_url'];
  }

  Future<void> _pickPdf() async {
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
    });
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _coverBase64 = base64Encode(file.bytes!);
      _coverName = file.name;
      _coverMime = 'image/${file.extension ?? 'jpeg'}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = BookPayload(
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
      genre: _genre,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      year: _yearCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_yearCtrl.text.trim()),
      language: _language,
      publisher: _publisherCtrl.text.trim().isEmpty
          ? null
          : _publisherCtrl.text.trim(),
      pages: _pagesCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_pagesCtrl.text.trim()),
      isbn: _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
      // PDF
      fileBase64: _fileBase64,
      fileName: _fileName,
      mimeType: _fileBase64 != null ? 'application/pdf' : null,
      existingFileUrl: _fileBase64 == null ? _existingFileUrl : null,
      // Cover
      coverBase64: _coverBase64,
      coverName: _coverName,
      coverMime: _coverMime,
      existingCoverUrl: _coverBase64 == null ? _existingCoverUrl : null,
    );

    try {
      if (_isEdit) {
        await BookService.updateBook(widget.book!['id'], payload);
      } else {
        await BookService.createBook(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
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
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4C1D95), _purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28)),
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(_isEdit ? 'Edit Book' : 'Upload Book',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ),

            // ── Form ────────────────────────────────────────────────────────
            Expanded(
              child: Form(
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

                    _sectionHeader('Book Details'),
                    const SizedBox(height: 10),

                    _card(
                        cardBg,
                        'Title *',
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: _deco('Book title'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                    const SizedBox(height: 12),

                    _card(
                        cardBg,
                        'Author *',
                        TextFormField(
                          controller: _authorCtrl,
                          decoration: _deco('Author name'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        )),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(
                        child: _card(
                            cardBg,
                            'Genre *',
                            DropdownButtonFormField<String>(
                              value: _genre,
                              decoration: _deco(null),
                              dropdownColor: cardBg,
                              items: _genres
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) => setState(() => _genre = v!),
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _card(
                            cardBg,
                            'Language',
                            DropdownButtonFormField<String>(
                              value: _language,
                              decoration: _deco(null),
                              dropdownColor: cardBg,
                              items: _languages
                                  .map((l) => DropdownMenuItem(
                                      value: l, child: Text(l)))
                                  .toList(),
                              onChanged: (v) => setState(() => _language = v!),
                            )),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(
                        child: _card(
                            cardBg,
                            'Year',
                            TextFormField(
                              controller: _yearCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _deco('e.g. 2021'),
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _card(
                            cardBg,
                            'Pages',
                            TextFormField(
                              controller: _pagesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _deco('e.g. 320'),
                            )),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    _card(
                        cardBg,
                        'Publisher',
                        TextFormField(
                          controller: _publisherCtrl,
                          decoration: _deco('Publisher name'),
                        )),
                    const SizedBox(height: 12),

                    _card(
                        cardBg,
                        'ISBN',
                        TextFormField(
                          controller: _isbnCtrl,
                          decoration: _deco('ISBN-10 or ISBN-13'),
                        )),
                    const SizedBox(height: 12),

                    _card(
                        cardBg,
                        'Description',
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 5,
                          decoration: _deco('Brief description of the book'),
                        )),
                    const SizedBox(height: 24),

                    _sectionHeader('Cover Image'),
                    const SizedBox(height: 10),
                    _card(
                        cardBg,
                        'Book Cover',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Preview
                            if (_coverBase64 != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(_coverBase64!),
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ] else if (_existingCoverUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _existingCoverUrl!,
                                  height: 120,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _purple)),
                              onPressed: _pickCover,
                              icon: const Icon(Icons.image_rounded,
                                  color: _purple),
                              label: Text(
                                _coverBase64 != null ||
                                        _existingCoverUrl != null
                                    ? 'Change Cover'
                                    : 'Upload Cover',
                                style: const TextStyle(color: _purple),
                              ),
                            ),
                          ],
                        )),
                    const SizedBox(height: 20),

                    _sectionHeader('PDF File'),
                    const SizedBox(height: 10),
                    _card(
                        cardBg,
                        'Book PDF',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_fileBase64 != null)
                              _fileChip(
                                  _fileName ?? 'PDF selected', Colors.green)
                            else if (_existingFileUrl != null)
                              _fileChip('Existing PDF attached', Colors.green),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _purple)),
                              onPressed: _pickPdf,
                              icon: const Icon(Icons.upload_file_rounded,
                                  color: _purple),
                              label: Text(
                                _fileBase64 != null
                                    ? 'Change PDF'
                                    : _existingFileUrl != null
                                        ? 'Replace PDF'
                                        : 'Upload PDF',
                                style: const TextStyle(color: _purple),
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
                          backgroundColor: _purple,
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
                                _isEdit ? 'Save Changes' : 'Upload Book',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
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
                color: _purple,
                letterSpacing: 0.5)),
      );

  Widget _card(Color cardBg, String label, Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _purple.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: _purple, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 8),
          child,
        ]),
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
