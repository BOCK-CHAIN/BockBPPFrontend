// lib/screens/library_screen.dart
import 'package:flutter/material.dart';
import '../core/session.dart';
import '../services/book_service.dart';
import 'book_detail_screen.dart';
import 'book_form_screen.dart';

class LibraryScreen extends StatefulWidget {
  final String initialSearch;
  final String? initialGenre;

  const LibraryScreen({
    super.key,
    this.initialSearch = '',
    this.initialGenre,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _purple = Color(0xFF6C3CE1);

  late final TextEditingController _searchCtrl;
  List<dynamic> _books = [];
  bool _loading = true;
  String? _error;
  String? _filterGenre;
  String? _currentUserId;

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

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearch);
    _filterGenre = widget.initialGenre;
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      final data = await BookService.getBooks(
        search: _searchCtrl.text,
        genre: _filterGenre,
      );
      if (mounted) setState(() => _books = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Delete "$title"? This cannot be undone.'),
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
      await BookService.deleteBook(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  bool _isOwner(Map<String, dynamic> book) =>
      _currentUserId != null && book['created_by'] == _currentUserId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF6F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text('Library',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const Spacer(),
                      // Any user can upload
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BookFormScreen()));
                          _load();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _load(),
                      decoration: const InputDecoration(
                        hintText: 'Search title, author...',
                        hintStyle: TextStyle(color: Colors.white54),
                        prefixIcon:
                            Icon(Icons.search_rounded, color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Genre filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filterGenre == null,
                          onTap: () {
                            setState(() => _filterGenre = null);
                            _load();
                          },
                        ),
                        ..._genres.map((g) => _FilterChip(
                              label: g,
                              selected: _filterGenre == g,
                              onTap: () {
                                setState(() => _filterGenre =
                                    _filterGenre == g ? null : g);
                                _load();
                              },
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Book list ────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _books.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _books.length,
                                itemBuilder: (_, i) {
                                  final b = _books[i];
                                  return _BookCard(
                                    book: b,
                                    isOwner: _isOwner(b),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BookDetailScreen(id: b['id']),
                                        ),
                                      );
                                      _load();
                                    },
                                    onEdit: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BookFormScreen(book: b),
                                        ),
                                      );
                                      _load();
                                    },
                                    onDelete: () =>
                                        _delete(b['id'], b['title']),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1), shape: BoxShape.circle),
            child:
                const Icon(Icons.menu_book_rounded, color: _purple, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('No books yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap + to upload the first book',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ]),
      );

  Widget _buildError() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
}

// ── Filter chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? const Color(0xFF6C3CE1) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              )),
        ),
      );
}

// ── Book card ─────────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  static const _purple = Color(0xFF6C3CE1);

  final Map<String, dynamic> book;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.isOwner,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final coverUrl = book['cover_url'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _purple.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: coverUrl != null
                  ? Image.network(coverUrl,
                      width: 70,
                      height: 98,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderCover())
                  : _placeholderCover(),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(book['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isOwner) ...[
                        GestureDetector(
                          onTap: onEdit,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.edit_rounded,
                                size: 18, color: Colors.blueAccent),
                          ),
                        ),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(Icons.delete_rounded,
                                size: 18, color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(book['author'] ?? '',
                      style: TextStyle(
                          color: _purple,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (book['genre'] != null)
                      _chip(Icons.category_rounded, book['genre'], _purple),
                    if (book['year'] != null)
                      _chip(Icons.calendar_today_rounded,
                          book['year'].toString(), Colors.teal),
                    if (book['language'] != null)
                      _chip(Icons.language_rounded, book['language'],
                          Colors.indigo),
                    if (book['pages'] != null)
                      _chip(Icons.menu_book_rounded, '${book['pages']} pages',
                          Colors.blueGrey),
                    if (book['file_url'] != null)
                      _chip(Icons.picture_as_pdf_rounded, 'PDF', Colors.green),
                  ]),
                  if (book['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(book['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCover() => Container(
        width: 70,
        height: 98,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF6C3CE1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            (book['title'] as String? ?? 'B').substring(0, 1).toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
        ),
      );

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}
