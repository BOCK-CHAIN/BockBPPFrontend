// lib/screens/my_contributions_screen.dart
import 'package:flutter/material.dart';
import '../core/session.dart';
import 'patent_detail_screen.dart';
import 'scholar_detail_screen.dart';
import 'book_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyContributionsScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final bool readOnly;

  const MyContributionsScreen({super.key})
      : userId = null,
        userName = null,
        readOnly = false;
  const MyContributionsScreen.user({
    super.key,
    required this.userId,
    this.userName,
  }) : readOnly = true;

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  static const _purple = Color(0xFF6C3CE1);
  static const _bg = Color(0xFF0D0B1A);
  static const _purpleHi = Color(0xFFA87EFF);
  static const _textSec = Color(0xFF9A84C2);
  static const _textMut = Color(0xFF4E3D78);

  List<dynamic> _patents = [];
  List<dynamic> _papers = [];
  List<dynamic> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sid = await Session.getSessionId();
      final headers = {
        'Content-Type': 'application/json',
        if (sid != null) 'x-session-id': sid,
      };
      final userId = widget.userId;
      Map<String, dynamic> body;

      if (userId == null || userId.isEmpty) {
        final res = await http.get(
          Uri.parse('http://localhost:3000/contributions/mine'),
          headers: headers,
        );
        body = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 200) {
          throw body['error'] ?? 'Failed to load contributions';
        }
      } else {
        final res = await http.get(
          Uri.parse('http://localhost:3000/contributions/user/$userId'),
          headers: headers,
        );
        body = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode != 200) {
          throw body['error'] ?? 'Failed to load user contributions';
        }
      }

      setState(() {
        _patents = body['patents'] as List? ?? [];
        _papers = body['papers'] as List? ?? [];
        _books = body['books'] as List? ?? [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _patents.length + _papers.length + _books.length;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                      const Icon(Icons.dashboard_customize_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                          widget.userId == null
                              ? 'My Contributions'
                              : '${widget.userName ?? "User"} Contributions',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                  if (!_loading && _error == null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(
                            icon: Icons.lightbulb_rounded,
                            label: '${_patents.length} Patents',
                            color: const Color(0xFF8B60E8)),
                        const SizedBox(width: 8),
                        _StatChip(
                            icon: Icons.science_rounded,
                            label: '${_papers.length} Papers',
                            color: const Color(0xFF00BCD4)),
                        const SizedBox(width: 8),
                        _StatChip(
                            icon: Icons.menu_book_rounded,
                            label: '${_books.length} Books',
                            color: const Color(0xFF4CAF50)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Body
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _purpleHi))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent, size: 48),
                              const SizedBox(height: 12),
                              Text(_error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: _textSec)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                  onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : total == 0
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: _purple.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.inbox_rounded,
                                        color: _purpleHi, size: 48),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No contributions yet',
                                      style: TextStyle(
                                          color: _purpleHi,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Add patents, papers or books to see them here',
                                      style: TextStyle(
                                          color: _textMut, fontSize: 13)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  if (_patents.isNotEmpty) ...[
                                    _SectionHeader(
                                      icon: Icons.lightbulb_rounded,
                                      label: 'Patents',
                                      count: _patents.length,
                                      color: const Color(0xFF8B60E8),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._patents.map((p) => _ContributionCard(
                                          title: p['title'] ?? 'Untitled',
                                          subtitle: p['category'] ?? 'Patent',
                                          badge: p['status'] ?? 'Draft',
                                          badgeColor: _statusColor(
                                              p['status'], 'patent'),
                                          meta: p['filing_date'] != null
                                              ? 'Filed: ${p['filing_date'].toString().substring(0, 10)}'
                                              : p['created_at'] != null
                                                  ? 'Added: ${p['created_at'].toString().substring(0, 10)}'
                                                  : '',
                                          icon: Icons.lightbulb_rounded,
                                          color: const Color(0xFF8B60E8),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    PatentDetailScreen(
                                                        id: p['id'])),
                                          ),
                                        )),
                                    const SizedBox(height: 24),
                                  ],
                                  if (_papers.isNotEmpty) ...[
                                    _SectionHeader(
                                      icon: Icons.science_rounded,
                                      label: 'Scholar Papers',
                                      count: _papers.length,
                                      color: const Color(0xFF00BCD4),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._papers.map((p) => _ContributionCard(
                                          title: p['title'] ?? 'Untitled',
                                          subtitle: p['venue_type'] ?? 'Paper',
                                          badge: p['status'] ?? 'Draft',
                                          badgeColor: _statusColor(
                                              p['status'], 'paper'),
                                          meta: p['year'] != null
                                              ? 'Year: ${p['year']}'
                                              : p['created_at'] != null
                                                  ? 'Added: ${p['created_at'].toString().substring(0, 10)}'
                                                  : '',
                                          icon: Icons.science_rounded,
                                          color: const Color(0xFF00BCD4),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    ScholarDetailScreen(
                                                        id: p['id'])),
                                          ),
                                        )),
                                    const SizedBox(height: 24),
                                  ],
                                  if (_books.isNotEmpty) ...[
                                    _SectionHeader(
                                      icon: Icons.menu_book_rounded,
                                      label: 'Library Books',
                                      count: _books.length,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                    const SizedBox(height: 10),
                                    ..._books.map((b) => _ContributionCard(
                                          title: b['title'] ?? 'Untitled',
                                          subtitle: b['author'] ?? '',
                                          badge: b['genre'] ?? 'Book',
                                          badgeColor: const Color(0xFF4CAF50),
                                          meta: b['created_at'] != null
                                              ? 'Added: ${b['created_at'].toString().substring(0, 10)}'
                                              : '',
                                          icon: Icons.menu_book_rounded,
                                          color: const Color(0xFF4CAF50),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    BookDetailScreen(
                                                        id: b['id'])),
                                          ),
                                        )),
                                    const SizedBox(height: 24),
                                  ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String? status, String type) {
    if (type == 'patent') {
      switch (status) {
        case 'Published':
          return Colors.blue;
        case 'Approved':
          return Colors.green;
        case 'Rejected':
          return Colors.red;
        default:
          return Colors.orange;
      }
    }
    switch (status) {
      case 'Published':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.icon,
      required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final String meta;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContributionCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.meta,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13101F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFE8E4F0),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF9A84C2), fontSize: 12)),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(meta,
                        style: const TextStyle(
                            color: Color(0xFF4E3D78), fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF4E3D78), size: 18),
          ],
        ),
      ),
    );
  }
}
