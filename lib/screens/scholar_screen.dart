// lib/screens/scholar_screen.dart
import 'package:flutter/material.dart';
import 'package:scholar/core/json_utils.dart';
import '../services/scholar_service.dart';
import 'scholar_detail_screen.dart';
import 'scholar_form_screen.dart';

class ScholarScreen extends StatefulWidget {
  final String initialSearch;
  final String? initialVenueType;
  final int? initialYear;

  const ScholarScreen({
    super.key,
    this.initialSearch = '',
    this.initialVenueType,
    this.initialYear,
  });

  @override
  State<ScholarScreen> createState() => _ScholarScreenState();
}

class _ScholarScreenState extends State<ScholarScreen> {
  static const color = Color(0xFF6C3CE1);
  late final TextEditingController _searchCtrl;
  List<dynamic> _papers = [];
  bool _loading = true;
  String? _error;
  String? _filterType;

  static const _venueTypes = [
    'Journal',
    'Conference',
    'Thesis',
    'Preprint',
    'Workshop'
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialSearch);
    _filterType = widget.initialVenueType;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ScholarService.getPapers(
        search: _searchCtrl.text,
        venueType: _filterType,
        year: widget.initialYear,
      );
      setState(() => _papers = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Paper'),
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
      await ScholarService.deletePaper(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF6F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
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
                      const Icon(Icons.science_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text('Papers',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ScholarFormScreen()));
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
                        hintText: 'Search title, abstract, venue...',
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                            label: 'All',
                            selected: _filterType == null,
                            onTap: () {
                              setState(() => _filterType = null);
                              _load();
                            }),
                        ..._venueTypes.map((t) => _FilterChip(
                              label: t,
                              selected: _filterType == t,
                              onTap: () {
                                setState(() =>
                                    _filterType = _filterType == t ? null : t);
                                _load();
                              },
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _papers.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _papers.length,
                                itemBuilder: (_, i) => _PaperCard(
                                  paper: _papers[i],
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ScholarDetailScreen(
                                                id: _papers[i]['id'])));
                                    _load();
                                  },
                                  onEdit: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ScholarFormScreen(
                                                paper: _papers[i])));
                                    _load();
                                  },
                                  onDelete: () => _delete(
                                      _papers[i]['id'], _papers[i]['title']),
                                ),
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
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.science_rounded, color: color, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('No papers found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('No papers available',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
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
}

class _PaperCard extends StatelessWidget {
  static const color = Color(0xFF6C3CE1);
  final Map<String, dynamic> paper;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaperCard({
    required this.paper,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _venueIcon(String? type) {
    switch (type) {
      case 'Journal':
        return Icons.menu_book_rounded;
      case 'Conference':
        return Icons.people_rounded;
      case 'Thesis':
        return Icons.school_rounded;
      case 'Preprint':
        return Icons.drafts_rounded;
      case 'Workshop':
        return Icons.handyman_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final authors = parseStringList(paper['authors']);
    final venueType = paper['venue_type'] as String?;
    final coverUrl = paper['cover_url'] as String?;
    final refCount = parseJsonList(paper['references_made']).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      width: 70,
                      height: 98,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderCover(),
                    )
                  : _placeholderCover(),
            ),
            const SizedBox(width: 14),

            // ── Info ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(paper['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
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
                  ),
                  if (authors.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(authors.join(', '),
                        style: const TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (venueType != null)
                      _chip(Icons.info_rounded, venueType, color),
                    if (paper['year'] != null)
                      _chip(Icons.calendar_today_rounded,
                          paper['year'].toString(), Colors.teal),
                    if (paper['venue'] != null)
                      _chip(Icons.location_on_rounded, paper['venue'],
                          Colors.indigo),
                    if (refCount > 0)
                      _chip(
                          Icons.link_rounded,
                          '$refCount ref${refCount == 1 ? '' : 's'}',
                          Colors.blueAccent),
                    if (paper['file_url'] != null)
                      _chip(Icons.picture_as_pdf_rounded, 'PDF', Colors.green),
                  ]),
                  if (paper['abstract'] != null) ...[
                    const SizedBox(height: 8),
                    Text(paper['abstract'],
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
            (paper['title'] as String? ?? 'P').substring(0, 1).toUpperCase(),
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}
