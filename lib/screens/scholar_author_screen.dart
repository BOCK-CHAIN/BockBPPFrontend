// lib/screens/scholar_author_screen.dart
import 'package:flutter/material.dart';

import 'package:bpp/core/json_utils.dart';
import '../services/scholar_service.dart';
import 'scholar_detail_screen.dart';

class ScholarAuthorScreen extends StatefulWidget {
  final String name;
  const ScholarAuthorScreen({super.key, required this.name});

  @override
  State<ScholarAuthorScreen> createState() => _ScholarAuthorScreenState();
}

class _ScholarAuthorScreenState extends State<ScholarAuthorScreen> {
  static const color = Color(0xFF6C3CE1);
  List<dynamic> _papers = [];
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
      final data = await ScholarService.getAuthorPapers(widget.name);
      setState(() => _papers = data['papers'] as List? ?? []);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: const BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                      '${_papers.length} paper${_papers.length == 1 ? '' : 's'}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _papers.isEmpty
                          ? Center(
                              child: Text('No papers found',
                                  style:
                                      TextStyle(color: Colors.grey.shade500)))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  Text('Papers',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.grey.shade400)),
                                  const SizedBox(height: 12),
                                  ..._papers.map((p) {
                                    final authors =
                                        parseStringList(p['authors']);
                                    return GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ScholarDetailScreen(
                                                      id: p['id']))),
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: color.withValues(
                                                  alpha: 0.15)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(p['title'] ?? '',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14),
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis),
                                                ),
                                                if (p['year'] != null) ...[
                                                  const SizedBox(width: 8),
                                                  Text(p['year'].toString(),
                                                      style: const TextStyle(
                                                          color: color,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13)),
                                                ],
                                              ],
                                            ),
                                            if (p['venue'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(p['venue'],
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 12)),
                                            ],
                                            if (authors.length > 1) ...[
                                              const SizedBox(height: 4),
                                              Text(authors.join(', '),
                                                  style: TextStyle(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontSize: 11),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                if (p['venue_type'] != null)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(
                                                          alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(p['venue_type'],
                                                        style: const TextStyle(
                                                            color: color,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  )
                                                else
                                                  const SizedBox.shrink(),
                                                const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: color,
                                                    size: 18),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
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
