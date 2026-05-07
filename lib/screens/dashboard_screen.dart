// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../core/session.dart';
import '../services/patent_service.dart';
import '../services/scholar_service.dart';
import 'patents_screen.dart';
import 'scholar_screen.dart';
import 'library_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════
class _AppTheme {
  final bool dark;
  const _AppTheme({required this.dark});

  Color get bg => dark ? const Color(0xFF0D0B1A) : const Color(0xFFF5F2FF);
  Color get surface => dark ? const Color(0xFF13101F) : const Color(0xFFFFFFFF);
  Color get purpleSub =>
      dark ? const Color(0xFF1C1335) : const Color(0xFFEDE8FF);
  Color get border => dark ? const Color(0xFF2A1F4A) : const Color(0xFFD0C4F0);
  Color get purple => const Color(0xFF7340D8);
  Color get purpleHi =>
      dark ? const Color(0xFFA87EFF) : const Color(0xFF6020C0);
  Color get textPri => dark ? const Color(0xFFE8E4F0) : const Color(0xFF18103A);
  Color get textSec => dark ? const Color(0xFF9A84C2) : const Color(0xFF6A50A0);
  Color get textMut => dark ? const Color(0xFF4E3D78) : const Color(0xFFB0A0D8);
}

// ═══════════════════════════════════════════════════════════════════════════
// VIEW MODELS
// ═══════════════════════════════════════════════════════════════════════════
class _BookData {
  final String title, author, year, initial;
  final Color topColor, bottomColor;
  const _BookData({
    required this.title,
    required this.author,
    required this.year,
    required this.topColor,
    required this.bottomColor,
    required this.initial,
  });
}

class _PaperData {
  final String title, author, year, tag;
  const _PaperData(
      {required this.title,
      required this.author,
      required this.year,
      required this.tag});
}

_PaperData _patentFromJson(Map<String, dynamic> j) {
  final inventors = (j['patent_inventors'] as List?) ?? [];
  String author = 'Unknown';
  if (inventors.isNotEmpty) {
    final first = inventors[0]['inventors']?['name'] ?? '';
    author = inventors.length > 1 ? '$first et al.' : first;
  } else if (j['assignee'] != null) {
    author = j['assignee'] as String;
  }
  final year = j['publication_date'] != null
      ? (j['publication_date'] as String).substring(0, 4)
      : (j['filing_date'] != null
          ? (j['filing_date'] as String).substring(0, 4)
          : '—');
  return _PaperData(
    title: j['title'] as String? ?? 'Untitled',
    author: author,
    year: year,
    tag: j['category'] as String? ?? 'Patent',
  );
}

_PaperData _scholarFromJson(Map<String, dynamic> j) {
  final authors = (j['authors'] as List?) ?? [];
  final author = authors.isEmpty
      ? 'Unknown'
      : authors.length > 1
          ? '${authors[0]} et al.'
          : authors[0] as String;
  return _PaperData(
    title: j['title'] as String? ?? 'Untitled',
    author: author,
    year: j['year']?.toString() ?? '—',
    tag: j['venue_type'] as String? ?? 'Paper',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchCtrl = TextEditingController();
  final _bookScroll = ScrollController();
  final _scholarScroll = ScrollController();
  final _patentScroll = ScrollController();

  int _activeTab = 0;
  bool _showFilters = false;
  String? _filterType;
  String? _filterYear;
  String? _userName;
  bool _darkMode = true;

  _AppTheme get _theme => _AppTheme(dark: _darkMode);

  List<_PaperData> _patents = [];
  List<_PaperData> _papers = [];
  bool _patentsLoading = true;
  bool _papersLoading = true;
  String? _patentsError;
  String? _papersError;

  static const _placeholderBooks = [
    _BookData(
        title: 'Dune',
        author: 'Frank Herbert',
        year: '1965',
        topColor: Color(0xFFC8860A),
        bottomColor: Color(0xFF3D1F00),
        initial: 'D'),
    _BookData(
        title: 'Sapiens',
        author: 'Y. N. Harari',
        year: '2011',
        topColor: Color(0xFF1A3A6B),
        bottomColor: Color(0xFF0A1F3D),
        initial: 'S'),
    _BookData(
        title: 'Atomic Habits',
        author: 'James Clear',
        year: '2018',
        topColor: Color(0xFF1C5C2E),
        bottomColor: Color(0xFF0A2A14),
        initial: 'A'),
    _BookData(
        title: 'Deep Work',
        author: 'Cal Newport',
        year: '2016',
        topColor: Color(0xFF4A1D96),
        bottomColor: Color(0xFF1E0A3C),
        initial: 'D'),
    _BookData(
        title: 'Thinking F&S',
        author: 'D. Kahneman',
        year: '2011',
        topColor: Color(0xFF7A1C1C),
        bottomColor: Color(0xFF2D0A0A),
        initial: 'T'),
    _BookData(
        title: 'The Lean Startup',
        author: 'Eric Ries',
        year: '2011',
        topColor: Color(0xFF1A5A6B),
        bottomColor: Color(0xFF0A2530),
        initial: 'L'),
  ];

  static const _tabs = ['Library', 'Scholar', 'Patents'];
  static const _years = ['2024', '2023', '2022', '2021', '2020', '2019'];
  static const _libGenres = [
    'Fiction',
    'Non-Fiction',
    'Science',
    'Technology',
    'History',
    'Biography'
  ];
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

  List<String> get _currentFilters => switch (_activeTab) {
        1 => _schTypes,
        2 => _patCats,
        _ => _libGenres,
      };
  String get _filterLabel => switch (_activeTab) {
        1 => 'Type',
        2 => 'Category',
        _ => 'Genre',
      };

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchPatents();
    _fetchPapers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bookScroll.dispose();
    _scholarScroll.dispose();
    _patentScroll.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final name = await Session.getFirstName();
    if (mounted) setState(() => _userName = name ?? 'Guest');
  }

  Future<void> _fetchPatents() async {
    setState(() {
      _patentsLoading = true;
      _patentsError = null;
    });
    try {
      final raw = await PatentService.getPatents();
      if (mounted)
        setState(() {
          _patents =
              raw.cast<Map<String, dynamic>>().map(_patentFromJson).toList();
          _patentsLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _patentsError = e.toString();
          _patentsLoading = false;
        });
    }
  }

  Future<void> _fetchPapers() async {
    setState(() {
      _papersLoading = true;
      _papersError = null;
    });
    try {
      final raw = await ScholarService.getPapers();
      if (mounted)
        setState(() {
          _papers =
              raw.cast<Map<String, dynamic>>().map(_scholarFromJson).toList();
          _papersLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _papersError = e.toString();
          _papersLoading = false;
        });
    }
  }

  void _goTo(int index, {String query = ''}) {
    final q = query.isNotEmpty ? query : _searchCtrl.text.trim();
    final Widget screen = switch (index) {
      1 => ScholarScreen(
          initialSearch: q,
          initialVenueType: _filterType,
          initialYear: _filterYear != null ? int.tryParse(_filterYear!) : null),
      2 => PatentsScreen(initialSearch: q, initialCategory: _filterType),
      _ => const LibraryScreen(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout() async {
    await Session.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _scrollBy(ScrollController ctrl, double delta) {
    final target =
        (ctrl.offset + delta).clamp(0.0, ctrl.position.maxScrollExtent);
    ctrl.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = _theme;
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 600;

    final bookCardW = isWide ? (screenW / 5).clamp(180.0, 260.0) : 148.0;
    final bookRowH = isWide ? bookCardW * 1.45 : 220.0;
    final paperCardW = isWide ? (screenW / 6).clamp(150.0, 220.0) : 180.0;
    final paperRowH = isWide ? paperCardW * 0.95 : 165.0;
    final scrollStep = isWide ? screenW * 0.55 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: t.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(t: t, isWide: isWide),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(t: t, isWide: isWide),
                      SizedBox(height: isWide ? 48 : 32),

                      // Library (placeholder)
                      _RowHeader(
                          t: t,
                          icon: Icons.menu_book_rounded,
                          label: 'Most Popular',
                          sub: 'Library',
                          ctrl: _bookScroll,
                          isWide: isWide,
                          onScroll: (d) =>
                              _scrollBy(_bookScroll, d * (scrollStep / 220))),
                      const SizedBox(height: 14),
                      _BookCoverRow(
                          t: t,
                          books: _placeholderBooks,
                          ctrl: _bookScroll,
                          cardWidth: bookCardW,
                          rowHeight: bookRowH,
                          onTap: (title) => _goTo(0, query: title)),

                      SizedBox(height: isWide ? 48 : 32),

                      // Patents (live)
                      _RowHeader(
                          t: t,
                          icon: Icons.lightbulb_rounded,
                          label: 'Recently Added',
                          sub: 'Patents',
                          ctrl: _patentScroll,
                          isWide: isWide,
                          onScroll: (d) =>
                              _scrollBy(_patentScroll, d * (scrollStep / 220))),
                      const SizedBox(height: 14),
                      if (_patentsLoading)
                        _LoadingRow(t: t, rowHeight: paperRowH)
                      else if (_patentsError != null)
                        _ErrorRow(
                            t: t,
                            message: _patentsError!,
                            onRetry: _fetchPatents,
                            rowHeight: paperRowH)
                      else if (_patents.isEmpty)
                        _EmptyRow(
                            t: t, label: 'No patents yet', rowHeight: paperRowH)
                      else
                        _PaperCardRow(
                            t: t,
                            items: _patents,
                            ctrl: _patentScroll,
                            accentColor: const Color(0xFF8B60E8),
                            cardWidth: paperCardW,
                            rowHeight: paperRowH,
                            onTap: (title) => _goTo(2, query: title)),

                      SizedBox(height: isWide ? 48 : 32),

                      // Scholar (live)
                      _RowHeader(
                          t: t,
                          icon: Icons.science_rounded,
                          label: 'Recently Added',
                          sub: 'Scholar',
                          ctrl: _scholarScroll,
                          isWide: isWide,
                          onScroll: (d) => _scrollBy(
                              _scholarScroll, d * (scrollStep / 220))),
                      const SizedBox(height: 14),
                      if (_papersLoading)
                        _LoadingRow(t: t, rowHeight: paperRowH)
                      else if (_papersError != null)
                        _ErrorRow(
                            t: t,
                            message: _papersError!,
                            onRetry: _fetchPapers,
                            rowHeight: paperRowH)
                      else if (_papers.isEmpty)
                        _EmptyRow(
                            t: t, label: 'No papers yet', rowHeight: paperRowH)
                      else
                        _PaperCardRow(
                            t: t,
                            items: _papers,
                            ctrl: _scholarScroll,
                            accentColor: t.purpleHi,
                            cardWidth: paperCardW,
                            rowHeight: paperRowH,
                            onTap: (title) => _goTo(1, query: title)),

                      SizedBox(height: isWide ? 60 : 40),
                      _buildFooter(t: t),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({required _AppTheme t, required bool isWide}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: 14),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: t.textSec),
              children: [
                const TextSpan(text: 'Hello '),
                TextSpan(
                    text: _userName ?? '...',
                    style: TextStyle(
                        color: t.purpleHi, fontWeight: FontWeight.w600)),
                const TextSpan(text: ' 👋'),
              ],
            ),
          ),
          const Spacer(),
          _IconBtn(
            t: t,
            icon:
                _darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onTap: () => setState(() => _darkMode = !_darkMode),
          ),
          const SizedBox(width: 8),
          _IconBtn(t: t, icon: Icons.logout_rounded, onTap: _logout),
        ],
      ),
    );
  }

  Widget _buildHero({required _AppTheme t, required bool isWide}) {
    final hPad = isWide ? 40.0 : 20.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, isWide ? 48 : 36, hPad, 0),
      child: Column(
        children: [
          Center(
              child: Text('BPP',
                  style: TextStyle(
                      color: t.purpleHi,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      height: 1))),
          const SizedBox(height: 6),
          Center(
              child: Text('Library  ·  Scholar  ·  Patents',
                  style: TextStyle(
                      color: t.textMut, fontSize: 12, letterSpacing: 2.5))),
          SizedBox(height: isWide ? 40 : 32),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  // Tabs
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: t.purpleSub,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10)),
                      border: Border.all(color: t.border),
                    ),
                    child: Row(
                      children: List.generate(_tabs.length, (i) {
                        final sel = _activeTab == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeTab = i;
                                _filterType = null;
                                _filterYear = null;
                                _showFilters = false;
                              });
                              _goTo(i);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: sel
                                    ? t.purple.withValues(alpha: 0.28)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(i == 0 ? 9 : 0),
                                  topRight: Radius.circular(
                                      i == _tabs.length - 1 ? 9 : 0),
                                ),
                                border: sel
                                    ? Border(
                                        bottom: BorderSide(
                                            color: t.purpleHi, width: 2))
                                    : null,
                              ),
                              child: Text(_tabs[i],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: sel ? t.purpleHi : t.textSec,
                                    fontSize: 13,
                                    fontWeight:
                                        sel ? FontWeight.w600 : FontWeight.w400,
                                  )),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Search bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(Icons.search_rounded, color: t.textMut, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onSubmitted: (_) => _goTo(_activeTab),
                            style: TextStyle(color: t.textPri, fontSize: 15),
                            cursorColor: t.purpleHi,
                            decoration: InputDecoration(
                              hintText: 'Search ${[
                                "books",
                                "papers",
                                "patents"
                              ][_activeTab]}...',
                              hintStyle:
                                  TextStyle(color: t.textMut, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showFilters = !_showFilters),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.tune_rounded,
                                color: _showFilters ? t.purpleHi : t.textMut,
                                size: 20),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _goTo(_activeTab),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                                color: t.purple,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('Search',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filters
                  if (_showFilters) ...[
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: t.purpleSub,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: t.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FilterLabel(text: _filterLabel, t: t),
                          const SizedBox(height: 8),
                          _ChipRow(
                              t: t,
                              items: _currentFilters,
                              selected: _filterType,
                              onTap: (v) => setState(() =>
                                  _filterType = _filterType == v ? null : v)),
                          if (_activeTab != 0) ...[
                            const SizedBox(height: 12),
                            _FilterLabel(text: 'Year', t: t),
                            const SizedBox(height: 8),
                            _ChipRow(
                                t: t,
                                items: _years,
                                selected: _filterYear,
                                onTap: (v) => setState(() =>
                                    _filterYear = _filterYear == v ? null : v)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({required _AppTheme t}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: t.border))),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: [
          Text('BPP',
              style: TextStyle(
                  color: t.purpleHi,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5)),
          Text('·', style: TextStyle(color: t.textMut)),
          ..._tabs.asMap().entries.expand((e) => [
                GestureDetector(
                  onTap: () => _goTo(e.key),
                  child: Text(e.value,
                      style: TextStyle(color: t.textSec, fontSize: 12)),
                ),
                if (e.key < _tabs.length - 1)
                  Text('·', style: TextStyle(color: t.textMut, fontSize: 12)),
              ]),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATES
// ═══════════════════════════════════════════════════════════════════════════
class _LoadingRow extends StatelessWidget {
  final _AppTheme t;
  final double rowHeight;
  const _LoadingRow({required this.t, required this.rowHeight});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: rowHeight,
        child: Center(
            child:
                CircularProgressIndicator(color: t.purpleHi, strokeWidth: 2)),
      );
}

class _ErrorRow extends StatelessWidget {
  final _AppTheme t;
  final String message;
  final VoidCallback onRetry;
  final double rowHeight;
  const _ErrorRow(
      {required this.t,
      required this.message,
      required this.onRetry,
      required this.rowHeight});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: rowHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: t.textMut, size: 28),
              const SizedBox(height: 8),
              Text('Failed to load',
                  style: TextStyle(color: t.textSec, fontSize: 13)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                      color: t.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.border)),
                  child: Text('Retry',
                      style: TextStyle(color: t.purpleHi, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyRow extends StatelessWidget {
  final _AppTheme t;
  final String label;
  final double rowHeight;
  const _EmptyRow(
      {required this.t, required this.label, required this.rowHeight});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: rowHeight,
        child: Center(
            child:
                Text(label, style: TextStyle(color: t.textMut, fontSize: 13))),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROW HEADER
// ═══════════════════════════════════════════════════════════════════════════
class _RowHeader extends StatelessWidget {
  final _AppTheme t;
  final IconData icon;
  final String label, sub;
  final ScrollController ctrl;
  final ValueChanged<double> onScroll;
  final bool isWide;
  const _RowHeader(
      {required this.t,
      required this.icon,
      required this.label,
      required this.sub,
      required this.ctrl,
      required this.onScroll,
      this.isWide = false});

  @override
  Widget build(BuildContext context) {
    final hPad = isWide ? 40.0 : 20.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: [
          Icon(icon, color: t.purpleHi, size: isWide ? 20 : 16),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: t.textPri,
                  fontSize: isWide ? 20 : 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Text('· $sub',
              style: TextStyle(color: t.textSec, fontSize: isWide ? 16 : 13)),
          const Spacer(),
          _ArrowBtn(
              t: t,
              icon: Icons.chevron_left_rounded,
              onTap: () => onScroll(-220)),
          const SizedBox(width: 6),
          _ArrowBtn(
              t: t,
              icon: Icons.chevron_right_rounded,
              onTap: () => onScroll(220)),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final _AppTheme t;
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.t, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: t.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, color: t.purpleHi, size: 16),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// BOOK ROW
// ═══════════════════════════════════════════════════════════════════════════
class _BookCoverRow extends StatelessWidget {
  final _AppTheme t;
  final List<_BookData> books;
  final ScrollController ctrl;
  final ValueChanged<String> onTap;
  final double cardWidth, rowHeight;
  const _BookCoverRow(
      {required this.t,
      required this.books,
      required this.ctrl,
      required this.onTap,
      required this.cardWidth,
      required this.rowHeight});

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width > 600 ? 40.0 : 20.0;
    return SizedBox(
      height: rowHeight,
      child: ListView.builder(
        controller: ctrl,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        itemCount: books.length,
        itemBuilder: (_, i) {
          final b = books[i];
          return GestureDetector(
            onTap: () => onTap(b.title),
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11)),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [b.topColor, b.bottomColor],
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.initial,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    height: 1)),
                            const Spacer(),
                            Text(b.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.textSec, fontSize: 10)),
                        const SizedBox(height: 1),
                        Text(b.year,
                            style: TextStyle(color: t.textMut, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAPER ROW
// ═══════════════════════════════════════════════════════════════════════════
class _PaperCardRow extends StatelessWidget {
  final _AppTheme t;
  final List<_PaperData> items;
  final ScrollController ctrl;
  final Color accentColor;
  final ValueChanged<String> onTap;
  final double cardWidth, rowHeight;
  const _PaperCardRow(
      {required this.t,
      required this.items,
      required this.ctrl,
      required this.accentColor,
      required this.onTap,
      required this.cardWidth,
      required this.rowHeight});

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width > 600 ? 40.0 : 20.0;
    return SizedBox(
      height: rowHeight,
      child: ListView.builder(
        controller: ctrl,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final p = items[i];
          return GestureDetector(
            onTap: () => onTap(p.title),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: cardWidth,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(p.tag,
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Text(p.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.textPri,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35)),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                          child: Text(p.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: t.textSec, fontSize: 10))),
                      Text(p.year,
                          style: TextStyle(color: t.textMut, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════
class _IconBtn extends StatelessWidget {
  final _AppTheme t;
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.t, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: t.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Icon(icon, color: t.purpleHi, size: 17),
        ),
      );
}

class _FilterLabel extends StatelessWidget {
  final String text;
  final _AppTheme t;
  const _FilterLabel({required this.text, required this.t});
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            color: t.textMut,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2),
      );
}

class _ChipRow extends StatelessWidget {
  final _AppTheme t;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onTap;
  const _ChipRow(
      {required this.t,
      required this.items,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final sel = selected == item;
            return GestureDetector(
              onTap: () => onTap(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? t.purple : t.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? t.purple : t.border),
                ),
                child: Text(item,
                    style: TextStyle(
                        color: sel ? Colors.white : t.textSec,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          }).toList(),
        ),
      );
}
