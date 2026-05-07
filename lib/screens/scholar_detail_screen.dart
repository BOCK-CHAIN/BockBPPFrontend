// lib/screens/scholar_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/session.dart';
import '../services/scholar_service.dart';
import 'scholar_author_screen.dart';
import 'scholar_form_screen.dart';

class ScholarDetailScreen extends StatefulWidget {
  final String id;
  const ScholarDetailScreen({super.key, required this.id});

  @override
  State<ScholarDetailScreen> createState() => _ScholarDetailScreenState();
}

class _ScholarDetailScreenState extends State<ScholarDetailScreen> {
  static const color = Color(0xFF00BCD4);

  Map<String, dynamic>? _paper;
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
      final data = await ScholarService.getPaper(widget.id);
      setState(() => _paper = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  bool get _isOwner =>
      _currentUserId != null && _paper?['created_by'] == _currentUserId;

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDoi(String doi) async {
    final uri = Uri.parse('https://doi.org/$doi');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Paper'),
        content: const Text('Delete this paper? This cannot be undone.'),
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
      await ScholarService.deletePaper(widget.id);
      if (mounted) Navigator.pop(context);
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
                  const Text('Paper Detail',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Spacer(),
                  if (_isOwner) ...[
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ScholarFormScreen(paper: _paper)));
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10)),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _paper == null
                          ? const Center(child: Text('Paper not found'))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  Text(_paper!['title'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3)),
                                  const SizedBox(height: 12),
                                  _AuthorsRow(
                                      authors:
                                          (_paper!['authors'] as List? ?? [])
                                              .cast<String>()),
                                  const SizedBox(height: 16),
                                  _BibMeta(paper: _paper!, cardBg: cardBg),
                                  const SizedBox(height: 16),
                                  if (_paper!['abstract'] != null) ...[
                                    _Section(
                                      cardBg: cardBg,
                                      title: 'Abstract',
                                      icon: Icons.short_text_rounded,
                                      child: Text(_paper!['abstract'],
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              height: 1.7)),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if ((_paper!['keywords'] as List? ?? [])
                                      .isNotEmpty) ...[
                                    _Section(
                                      cardBg: cardBg,
                                      title: 'Keywords',
                                      icon: Icons.tag_rounded,
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: (_paper!['keywords'] as List)
                                            .map((k) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                        alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(k.toString(),
                                                      style: const TextStyle(
                                                          color: color,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_paper!['advisor'] != null ||
                                      _paper!['degree'] != null ||
                                      _paper!['department'] != null ||
                                      _paper!['institution'] != null) ...[
                                    _Section(
                                      cardBg: cardBg,
                                      title: 'Institution Details',
                                      icon: Icons.school_rounded,
                                      child: Column(
                                        children: [
                                          if (_paper!['institution'] != null)
                                            _MetaRow(
                                                Icons.apartment_rounded,
                                                'Institution',
                                                _paper!['institution']),
                                          if (_paper!['department'] != null)
                                            _MetaRow(
                                                Icons.domain_rounded,
                                                'Department',
                                                _paper!['department']),
                                          if (_paper!['degree'] != null)
                                            _MetaRow(
                                                Icons.workspace_premium_rounded,
                                                'Degree',
                                                _paper!['degree']),
                                          if (_paper!['advisor'] != null)
                                            _MetaRow(
                                                Icons.person_rounded,
                                                'Advisor/Supervisor',
                                                _paper!['advisor']),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_paper!['doi'] != null) ...[
                                    _Section(
                                      cardBg: cardBg,
                                      title: 'DOI',
                                      icon: Icons.link_rounded,
                                      child: GestureDetector(
                                        onTap: () => _openDoi(_paper!['doi']),
                                        onLongPress: () {
                                          Clipboard.setData(ClipboardData(
                                              text: _paper!['doi']));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text('DOI copied')));
                                        },
                                        child: Text(
                                          _paper!['doi'],
                                          style: const TextStyle(
                                              color: color,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _ReferencesSection(
                                    cardBg: cardBg,
                                    title: 'References',
                                    icon: Icons.format_list_numbered_rounded,
                                    refs: _paper!['references_made'] as List? ??
                                        [],
                                    keyName: 'cited_paper',
                                  ),
                                  const SizedBox(height: 16),
                                  _ReferencesSection(
                                    cardBg: cardBg,
                                    title: 'Cited By',
                                    icon: Icons.call_received_rounded,
                                    refs: _paper!['cited_by'] as List? ?? [],
                                    keyName: 'citing_paper',
                                  ),
                                  if (_paper!['file_url'] != null) ...[
                                    const SizedBox(height: 16),
                                    _Section(
                                      cardBg: cardBg,
                                      title: 'Document',
                                      icon: Icons.picture_as_pdf_rounded,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _openFile(_paper!['file_url']),
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
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Authors row ───────────────────────────────────────────────────────────────
class _AuthorsRow extends StatelessWidget {
  final List<String> authors;
  const _AuthorsRow({required this.authors});

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: authors
          .map((a) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ScholarAuthorScreen(name: a)),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 12, color: Color(0xFF00BCD4)),
                      const SizedBox(width: 4),
                      Text(a,
                          style: const TextStyle(
                              color: Color(0xFF00BCD4),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Bibliographic meta ────────────────────────────────────────────────────────
class _BibMeta extends StatelessWidget {
  final Map<String, dynamic> paper;
  final Color cardBg;
  const _BibMeta({required this.paper, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    final items = <_MetaItem>[];
    if (paper['venue'] != null)
      items.add(_MetaItem(Icons.location_on_rounded, 'Venue', paper['venue']));
    if (paper['venue_type'] != null)
      items.add(_MetaItem(Icons.category_rounded, 'Type', paper['venue_type']));
    if (paper['year'] != null)
      items.add(_MetaItem(
          Icons.calendar_today_rounded, 'Year', paper['year'].toString()));
    if (paper['volume'] != null)
      items.add(_MetaItem(Icons.layers_rounded, 'Volume', paper['volume']));
    if (paper['issue'] != null)
      items.add(_MetaItem(Icons.numbers_rounded, 'Issue', paper['issue']));
    if (paper['pages'] != null)
      items.add(_MetaItem(Icons.article_rounded, 'Pages', paper['pages']));
    if (paper['issn'] != null)
      items.add(_MetaItem(Icons.fingerprint_rounded, 'ISSN', paper['issn']));
    if (paper['isbn'] != null)
      items.add(_MetaItem(Icons.fingerprint_rounded, 'ISBN', paper['isbn']));
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF00BCD4).withValues(alpha: 0.15)),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        children: items
            .map((item) => SizedBox(
                  width: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, size: 14, color: const Color(0xFF00BCD4)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF00BCD4),
                                    fontWeight: FontWeight.bold)),
                            Text(item.value,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade400),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MetaItem {
  final IconData icon;
  final String label;
  final String value;
  const _MetaItem(this.icon, this.label, this.value);
}

// ── Meta row ──────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00BCD4)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF00BCD4),
                      fontWeight: FontWeight.bold)),
              Text(value,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── References section ────────────────────────────────────────────────────────
class _ReferencesSection extends StatelessWidget {
  final Color cardBg;
  final String title;
  final IconData icon;
  final List refs;
  final String keyName;

  const _ReferencesSection({
    required this.cardBg,
    required this.title,
    required this.icon,
    required this.refs,
    required this.keyName,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      cardBg: cardBg,
      title: '$title (${refs.length})',
      icon: icon,
      child: refs.isEmpty
          ? Text('None', style: TextStyle(color: Colors.grey.shade500))
          : Column(
              children: refs.asMap().entries.map((e) {
                final idx = e.key;
                final paper = e.value[keyName];
                if (paper == null) return const SizedBox.shrink();
                final authors =
                    (paper['authors'] as List? ?? []).cast<String>();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        const Color(0xFF00BCD4).withValues(alpha: 0.15),
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(paper['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      if (authors.isNotEmpty) authors.first,
                      if (paper['year'] != null) paper['year'].toString(),
                    ].join(' · '),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF00BCD4)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ScholarDetailScreen(id: paper['id'])),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final Color cardBg;
  final String title;
  final IconData icon;
  final Widget child;
  const _Section(
      {required this.cardBg,
      required this.title,
      required this.icon,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF00BCD4).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF00BCD4), size: 15),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF00BCD4))),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
