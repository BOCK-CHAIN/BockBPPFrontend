// lib/screens/inventor_screen.dart
import 'package:flutter/material.dart';
import '../services/patent_service.dart';
import 'patent_detail_screen.dart';

class InventorScreen extends StatefulWidget {
  final String id;
  const InventorScreen({super.key, required this.id});

  @override
  State<InventorScreen> createState() => _InventorScreenState();
}

class _InventorScreenState extends State<InventorScreen> {
  Map<String, dynamic>? _inventor;
  List<dynamic> _patents = [];
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
      final data = await PatentService.getInventor(widget.id);
      setState(() {
        _inventor = data['inventor'] as Map<String, dynamic>?;
        _patents = data['patents'] as List? ?? [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF6F4FF);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
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
                  if (_inventor != null) ...[
                    Text(
                      _inventor!['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_patents.length} patent${_patents.length == 1 ? '' : 's'}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
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
                      : _patents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lightbulb_outline_rounded,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text('No patents found',
                                      style: TextStyle(
                                          color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  Text('Patents',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.grey.shade400)),
                                  const SizedBox(height: 12),
                                  ..._patents.map((p) => GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PatentDetailScreen(id: p['id']),
                                          ),
                                        ),
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
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(
                                                      alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                    Icons.lightbulb_rounded,
                                                    color: color,
                                                    size: 18),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      p['title'] ?? '',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if (p['abstract'] !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        p['abstract'],
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey.shade500,
                                                            fontSize: 12),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Icon(Icons.chevron_right_rounded,
                                                  color: color),
                                            ],
                                          ),
                                        ),
                                      )),
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
