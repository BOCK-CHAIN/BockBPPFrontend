// lib/screens/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/session.dart';
import '../services/book_service.dart';
import 'book_form_screen.dart';
import 'my_contributions_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final String id;
  const BookDetailScreen({super.key, required this.id});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  static const _purple = Color(0xFF6C3CE1);

  Map<String, dynamic>? _book;
  List<dynamic> _similar = [];
  bool _loading = true;
  String? _error;
  String? _currentUserId;
  bool _descExpanded = false;

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
      final book = await BookService.getBook(widget.id);
      if (mounted) {
        setState(() {
          _book = book;
          _loading = false;
        });
        // Load similar books in background
        if (book['genre'] != null) {
          final sim = await BookService.getSimilar(book['genre'], widget.id);
          if (mounted) setState(() => _similar = sim);
        }
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  bool get _isOwner =>
      _currentUserId != null && _book?['created_by'] == _currentUserId;

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Delete this book? This cannot be undone.'),
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
      await BookService.deleteBook(widget.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Open PDF in browser (read online)
  Future<void> _readOnline() async {
    final url = _book?['file_url'] as String?;
    if (url == null) {
      _showSnack('No PDF available for this book');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open PDF');
    }
  }

  // Download PDF
  Future<void> _download() async {
    final url = _book?['file_url'] as String?;
    if (url == null) {
      _showSnack('No PDF available for this book');
      return;
    }
    // Launch the direct URL — browser will trigger download for PDF
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not download PDF');
    }
  }

  // Share
  Future<void> _share() async {
    final title = _book?['title'] ?? 'Book';
    final author = _book?['author'] ?? '';
    final fileUrl = _book?['file_url'] as String?;
    final text = fileUrl != null
        ? '📖 "$title" by $author\n\nRead / Download PDF:\n$fileUrl'
        : '📖 "$title" by $author — shared via BPP';
    await Share.share(text, subject: title);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF6F4FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }
    if (_book == null) {
      return Scaffold(
          backgroundColor: bg,
          body: const Center(child: Text('Book not found')));
    }

    final coverUrl = _book!['cover_url'] as String?;
    final fileUrl = _book!['file_url'] as String?;
    final desc = _book!['description'] as String?;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Hero header ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D1060), Color(0xFF6C3CE1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + actions
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      if (_isOwner) ...[
                        _headerBtn(Icons.edit_rounded, () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookFormScreen(book: _book)),
                          );
                          _load();
                        }),
                        const SizedBox(width: 10),
                        _headerBtn(Icons.delete_rounded, _delete),
                      ],
                    ]),
                    const SizedBox(height: 20),

                    // Cover + title block
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Cover
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: coverUrl != null
                              ? Image.network(
                                  coverUrl,
                                  width: 110,
                                  height: 155,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholderCover(
                                          width: 110, height: 155),
                                )
                              : _placeholderCover(width: 110, height: 155),
                        ),
                        const SizedBox(width: 18),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_book!['title'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.25)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  final uploader =
                                      _book!['uploader'] as Map<String, dynamic>?;
                                  final targetId = (uploader?['id'] ??
                                          _book!['created_by'] ??
                                          _book!['uploader_id'])
                                      ?.toString();
                                  if (targetId == null || targetId.isEmpty) {
                                    _showSnack('Author contributions unavailable');
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MyContributionsScreen.user(
                                        userId: targetId,
                                        userName: _book!['author']?.toString(),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(_book!['author'] ?? '',
                                    style: const TextStyle(
                                        color: Color(0xFFCDB4FF),
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFFCDB4FF))),
                              ),
                              const SizedBox(height: 12),
                              if (_book!['genre'] != null)
                                _whiteChip(
                                    Icons.category_rounded, _book!['genre']),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Action buttons row
                    Row(children: [
                      // Read Online
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.play_arrow_rounded,
                          label: 'Read Online',
                          filled: true,
                          enabled: fileUrl != null,
                          onTap: _readOnline,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Download PDF
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.download_rounded,
                          label: 'Download PDF',
                          filled: false,
                          enabled: fileUrl != null,
                          onTap: _download,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Share
                      _squareBtn(Icons.share_rounded, _share),
                    ]),
                  ],
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // About Book tab label
                  Text('ABOUT BOOK',
                      style: TextStyle(
                          color: _purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Divider(color: _purple.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),

                  // Description
                  if (desc != null && desc.isNotEmpty) ...[
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _descExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Text(desc,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, height: 1.6)),
                      secondChild: Text(desc,
                          style: const TextStyle(fontSize: 14, height: 1.6)),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _descExpanded = !_descExpanded),
                      child: Row(children: [
                        Text(
                          _descExpanded ? 'Show less ↑' : 'Read more ↓',
                          style: TextStyle(
                              color: _purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Metadata grid
                  _metaGrid(cardBg),
                  const SizedBox(height: 28),

                  // Similar Books
                  if (_similar.isNotEmpty) ...[
                    Text('You may also like',
                        style: TextStyle(
                            color: _purple,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similar.length,
                        itemBuilder: (_, i) => _SimilarCard(book: _similar[i]),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaGrid(Color cardBg) {
    final rows = <_MetaRow>[];
    if (_book!['genre'] != null)
      rows.add(_MetaRow('Categories', _book!['genre']));
    if (_book!['year'] != null)
      rows.add(_MetaRow('Year', _book!['year'].toString()));
    if (_book!['language'] != null)
      rows.add(_MetaRow('Language', _book!['language']));
    if (_book!['publisher'] != null)
      rows.add(_MetaRow('Publisher', _book!['publisher']));
    if (_book!['pages'] != null)
      rows.add(_MetaRow('Pages', _book!['pages'].toString()));
    if (_book!['isbn'] != null) rows.add(_MetaRow('ISBN', _book!['isbn']));
    final uploaderMap = _book!['uploader'] as Map?;
    if (uploaderMap != null) {
      final name =
          '${uploaderMap['first_name'] ?? ''} ${uploaderMap['last_name'] ?? ''}'
              .trim();
      if (name.isNotEmpty) rows.add(_MetaRow('Uploaded by', name));
    }
    if (_book!['file_url'] != null) rows.add(_MetaRow('File', 'PDF'));

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final row = e.value;
          final last = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(row.label,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(row.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              if (!last)
                Divider(height: 1, color: _purple.withValues(alpha: 0.08)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required bool filled,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: filled
                ? (enabled ? _purple : Colors.grey.shade600)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: filled
                ? null
                : Border.all(
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.grey.shade600),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: enabled ? Colors.white : Colors.grey.shade400,
                  size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _squareBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  Widget _whiteChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _placeholderCover({required double width, required double height}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            (_book!['title'] as String? ?? 'B').substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.35,
                fontWeight: FontWeight.w900),
          ),
        ),
      );
}

class _MetaRow {
  final String label, value;
  const _MetaRow(this.label, this.value);
}

// ── Similar book card ─────────────────────────────────────────────────────────
class _SimilarCard extends StatelessWidget {
  final Map<String, dynamic> book;
  const _SimilarCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final coverUrl = book['cover_url'] as String?;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(id: book['id'])),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: coverUrl != null
                  ? Image.network(coverUrl,
                      width: 120,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(120, 150))
                  : _placeholder(120, 150),
            ),
            const SizedBox(height: 6),
            Text(book['title'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(book['author'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF4C1D95), Color(0xFF6C3CE1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            (book['title'] as String? ?? 'B').substring(0, 1).toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ),
      );
}
