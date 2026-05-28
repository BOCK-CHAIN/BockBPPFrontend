// lib/screens/search_results_screen.dart
import 'package:flutter/material.dart';

import 'package:scholar/core/json_utils.dart';
import '../services/book_service.dart';
import '../services/scholar_service.dart';
import '../services/patent_service.dart';
import 'book_detail_screen.dart';
import 'scholar_detail_screen.dart';
import 'patents_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? filterType;
  final String? filterYear;
  final String? sortOrder; // 'az', 'za'

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.filterType,
    this.filterYear,
    this.sortOrder,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF7C3AED);
  static const _purpleHi = Color(0xFFA87EFF);
  static const _bg = Color(0xFF0D0B1A);
  static const _surface = Color(0xFF13101F);
  static const _border = Color(0xFF2A1F4A);

  late TabController _tabCtrl;

  List<dynamic> _scholars = [];
  List<dynamic> _patents = [];
  List<dynamic> _books = [];

  bool _scholarsLoading = true;
  bool _patentsLoading = true;
  bool _booksLoading = true;

  String? _scholarsError;
  String? _patentsError;
  String? _booksError;

  // local filter state (can be changed in this screen too)
  late String? _sortOrder;
  late String? _filterYear;
  late String? _filterType;

  static const _years = ['2024', '2023', '2022', '2021', '2020', '2019'];
  static const _schTypes = [
    'Journal',
    'Conference',
    'Thesis',
    'Preprint',
    'Workshop'
  ];
  static const _patCats = [
    'AI / ML',
    'Mechanical',
    'Electronics',
    'Biotech',
    'Chemical',
    'Software'
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _sortOrder = widget.sortOrder;
    _filterYear = widget.filterYear;
    _filterType = widget.filterType;
    _fetchAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    _fetchBooks();
    _fetchScholars();
    _fetchPatents();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _booksLoading = true;
      _booksError = null;
    });
    try {
      final data = await BookService.getBooks(
        search: widget.query,
        genre: _filterType,
        year: _filterYear != null ? int.tryParse(_filterYear!) : null,
      );
      final sorted = List<dynamic>.from(data);
      _applySort(sorted, 'title');
      setState(() {
        _books = sorted;
        _booksLoading = false;
      });
    } catch (e) {
      setState(() {
        _booksError = e.toString();
        _booksLoading = false;
      });
    }
  }

  Future<void> _fetchScholars() async {
    setState(() {
      _scholarsLoading = true;
      _scholarsError = null;
    });
    try {
      final data = await ScholarService.getPapers(
        search: widget.query,
        venueType: _filterType,
        year: _filterYear != null ? int.tryParse(_filterYear!) : null,
      );
      List<dynamic> sorted = List.from(data);
      _applySort(sorted, 'title');
      setState(() {
        _scholars = sorted;
        _scholarsLoading = false;
      });
    } catch (e) {
      setState(() {
        _scholarsError = e.toString();
        _scholarsLoading = false;
      });
    }
  }

  Future<void> _fetchPatents() async {
    setState(() {
      _patentsLoading = true;
      _patentsError = null;
    });
    try {
      final data = await PatentService.getPatents(
        search: widget.query,
        category: _filterType,
      );
      List<dynamic> sorted = List.from(data);
      _applySort(sorted, 'title');
      setState(() {
        _patents = sorted;
        _patentsLoading = false;
      });
    } catch (e) {
      setState(() {
        _patentsError = e.toString();
        _patentsLoading = false;
      });
    }
  }

  void _applySort(List<dynamic> list, String key) {
    if (_sortOrder == 'az') {
      list.sort((a, b) => (a[key] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b[key] ?? '').toString().toLowerCase()));
    } else if (_sortOrder == 'za') {
      list.sort((a, b) => (b[key] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((a[key] ?? '').toString().toLowerCase()));
    }
  }

  void _showFilterSheet() {
    String? tempSort = _sortOrder;
    String? tempYear = _filterYear;
    String? tempType = _filterType;

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Filters & Sort',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Sort
              _sheetLabel('Sort'),
              const SizedBox(height: 8),
              Row(children: [
                _filterChip(
                    'A → Z',
                    tempSort == 'az',
                    () => setModal(
                        () => tempSort = tempSort == 'az' ? null : 'az')),
                const SizedBox(width: 8),
                _filterChip(
                    'Z → A',
                    tempSort == 'za',
                    () => setModal(
                        () => tempSort = tempSort == 'za' ? null : 'za')),
              ]),
              const SizedBox(height: 16),

              // Year
              _sheetLabel('Year'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _years
                    .map((y) => _filterChip(
                          y,
                          tempYear == y,
                          () => setModal(
                              () => tempYear = tempYear == y ? null : y),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Type (tab-aware)
              _sheetLabel(_tabCtrl.index == 2 ? 'Category' : 'Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_tabCtrl.index == 2 ? _patCats : _schTypes)
                    .map(
                      (t) => _filterChip(
                          t,
                          tempType == t,
                          () => setModal(
                              () => tempType = tempType == t ? null : t)),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),

              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () {
                      setModal(() {
                        tempSort = null;
                        tempYear = null;
                        tempType = null;
                      });
                    },
                    child: const Text('Clear All',
                        style: TextStyle(color: _purpleHi)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: () {
                      setState(() {
                        _sortOrder = tempSort;
                        _filterYear = tempYear;
                        _filterType = tempType;
                      });
                      Navigator.pop(context);
                      _fetchAll();
                    },
                    child: const Text('Apply',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: _purpleHi,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      );

  Widget _filterChip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _purple : _purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _purple : _border),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        _sortOrder != null || _filterYear != null || _filterType != null;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: const BoxDecoration(
                color: Color(0xFF13101F),
                border: Border(bottom: BorderSide(color: _border)),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Search Results',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text('"${widget.query}"',
                                style: const TextStyle(
                                    color: _purpleHi, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Filter button
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasActiveFilters
                                ? _purple.withValues(alpha: 0.25)
                                : _purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: hasActiveFilters ? _purple : _border),
                          ),
                          child: Icon(Icons.tune_rounded,
                              color: hasActiveFilters ? _purpleHi : Colors.grey,
                              size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Active filter chips
                  if (hasActiveFilters) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_sortOrder != null)
                            _activeChip(
                                _sortOrder == 'az' ? 'A → Z' : 'Z → A',
                                () => setState(() {
                                      _sortOrder = null;
                                      _fetchAll();
                                    })),
                          if (_filterYear != null)
                            _activeChip(
                                _filterYear!,
                                () => setState(() {
                                      _filterYear = null;
                                      _fetchAll();
                                    })),
                          if (_filterType != null)
                            _activeChip(
                                _filterType!,
                                () => setState(() {
                                      _filterType = null;
                                      _fetchAll();
                                    })),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Tabs
                  TabBar(
                    controller: _tabCtrl,
                    indicatorColor: _purple,
                    indicatorWeight: 2,
                    labelColor: _purpleHi,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(
                          text:
                              'Books${_books.isNotEmpty ? ' (${_books.length})' : ''}'),
                      Tab(
                          text:
                              'Scholar${!_scholarsLoading && _scholarsError == null ? ' (${_scholars.length})' : ''}'),
                      Tab(
                          text:
                              'Patents${!_patentsLoading && _patentsError == null ? ' (${_patents.length})' : ''}'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // ── BOOKS ──
                  _buildBookTab(),

                  // ── SCHOLAR ──
                  _buildScholarTab(),

                  // ── PATENTS ──
                  _buildPatentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) => Container(
        margin: const EdgeInsets.only(right: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _purple.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: const TextStyle(
                  color: _purpleHi, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, color: _purpleHi, size: 13),
          ),
        ]),
      );

  // ── BOOKS TAB ─────────────────────────────────────────────────────────────
  Widget _buildBookTab() {
    if (_booksLoading) return _loadingState();
    if (_booksError != null) return _errorState(_booksError!, _fetchBooks);
    if (_books.isEmpty)
      return _emptyState(
        icon: Icons.menu_book_rounded,
        title: 'No existing books',
        sub: 'No books match your search',
      );

    return RefreshIndicator(
      onRefresh: _fetchBooks,
      color: _purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _books.length,
        itemBuilder: (_, i) {
          final b = _books[i] as Map<String, dynamic>;
          final author = b['author'] as String? ?? 'Unknown';
          final year = b['year']?.toString() ?? '—';
          final genre = b['genre'] as String? ?? 'Book';
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BookDetailScreen(id: b['id']))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: _purpleHi,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(genre,
                              style: const TextStyle(
                                  color: _purpleHi,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 6),
                        Text(b['title'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(author,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(year,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: _purpleHi, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── SCHOLAR TAB ───────────────────────────────────────────────────────────
  Widget _buildScholarTab() {
    if (_scholarsLoading) return _loadingState();
    if (_scholarsError != null)
      return _errorState(_scholarsError!, _fetchScholars);
    if (_scholars.isEmpty)
      return _emptyState(
        icon: Icons.science_rounded,
        title: 'No existing scholar',
        sub: 'No papers match "${widget.query}"',
      );

    return RefreshIndicator(
      onRefresh: _fetchScholars,
      color: _purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scholars.length,
        itemBuilder: (_, i) {
          final p = _scholars[i];
          final authors = parseStringList(p['authors']);
          final venueType = p['venue_type'] as String?;
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ScholarDetailScreen(id: p['id']))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Index number
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: _purpleHi,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (venueType != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(venueType,
                                style: const TextStyle(
                                    color: _purpleHi,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(p['title'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        if (authors.isNotEmpty)
                          Text(authors.join(', '),
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          if (p['year'] != null) ...[
                            Icon(Icons.calendar_today_rounded,
                                size: 11, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(p['year'].toString(),
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 11)),
                            const SizedBox(width: 12),
                          ],
                          if (p['venue'] != null) ...[
                            Icon(Icons.location_on_rounded,
                                size: 11, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(p['venue'],
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: _purpleHi, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── PATENTS TAB ───────────────────────────────────────────────────────────
  Widget _buildPatentTab() {
    if (_patentsLoading) return _loadingState();
    if (_patentsError != null)
      return _errorState(_patentsError!, _fetchPatents);
    if (_patents.isEmpty)
      return _emptyState(
        icon: Icons.lightbulb_rounded,
        title: 'No existing patents',
        sub: 'No patents match "${widget.query}"',
      );

    return RefreshIndicator(
      onRefresh: _fetchPatents,
      color: _purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patents.length,
        itemBuilder: (_, i) {
          final p = _patents[i] as Map<String, dynamic>;
          final inventors = parseJsonList(p['patent_inventors']);
          String author = 'Unknown';
          if (inventors.isNotEmpty) {
            final first = inventors[0]['inventors']?['name'] ?? '';
            author = inventors.length > 1 ? '$first et al.' : first;
          } else if (p['assignee'] != null) {
            author = p['assignee'] as String;
          }
          final year = p['publication_date'] != null
              ? (p['publication_date'] as String).substring(0, 4)
              : (p['filing_date'] != null
                  ? (p['filing_date'] as String).substring(0, 4)
                  : '—');
          final category = p['category'] as String? ?? 'Patent';

          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PatentsScreen(initialSearch: p['title'] ?? ''))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B60E8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Color(0xFF8B60E8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF8B60E8).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(category,
                              style: const TextStyle(
                                  color: Color(0xFF8B60E8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 6),
                        Text(p['title'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(author,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(year,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF8B60E8), size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _loadingState() => const Center(
        child: CircularProgressIndicator(color: _purple, strokeWidth: 2),
      );

  Widget _errorState(String msg, VoidCallback retry) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 40),
          const SizedBox(height: 12),
          Text('Failed to load',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          const SizedBox(height: 6),
          Text(msg,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: retry,
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ]),
      );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String sub,
  }) =>
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _purpleHi, size: 40),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(sub,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );
}
