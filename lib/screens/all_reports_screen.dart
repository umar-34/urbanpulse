import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// provider and report_provider no longer needed; using Firestore stream
import '../models/report.dart';
import '../widgets/status_badge.dart';
import '../widgets/report_card.dart';

class AllReportsScreen extends StatefulWidget {
  const AllReportsScreen({super.key});

  @override
  State<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends State<AllReportsScreen> {
  ReportStatus? _filterStatus;
  IssueCategory? _filterCategory;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Report> _applyFilters(List<Report> all) {
    return all.where((r) {
      if (_filterStatus != null && r.status != _filterStatus) return false;
      if (_filterCategory != null && r.category != _filterCategory) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!r.title.toLowerCase().contains(q) &&
            !r.location.toLowerCase().contains(q) &&
            !(r.description ?? '').toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          // ignore: avoid_print
          print('AllReports stream error: ${snap.error}');
          return const Scaffold(
              body: Center(child: Text('Something went wrong')));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF0F7F8),
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF064554), Color(0xFF0a6378)],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    size: 20, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'All Reports',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            body: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search reports…',
                      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF9E9E9E), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => const ReportListTileSkeleton(),
                  ),
                ),
              ],
            ),
          );
        }
        final docs = snap.data?.docs ?? [];
        final reports = docs.map((doc) {
          final data = doc.data();
          final id = doc.id;
          final categoryStr = (data['category'] ?? '').toString().trim();
          final statusStr = (data['status'] ?? '').toString().trim();
          final timestamp = data['timestamp'] as Timestamp?;
          final createdAt =
              timestamp != null ? timestamp.toDate() : DateTime.now();
          IssueCategory category = IssueCategory.other;
          try {
            final cs = categoryStr.toLowerCase();
            category = IssueCategory.values.firstWhere((e) =>
                e.name.toLowerCase() == cs || e.label.toLowerCase() == cs);
          } catch (_) {}
          ReportStatus status = ReportStatus.received;
          try {
            final s = statusStr.toLowerCase();
            if (s.contains('resolv')) {
              status = ReportStatus.resolved;
            } else if (s.contains('ai') || s.contains('verified')) {
              status = ReportStatus.aiVerified;
            } else if (s.contains('active') ||
                s.contains('pending') ||
                s.contains('in progress') ||
                s.contains('assigned')) {
              status = ReportStatus.assignedToDept;
            } else if (s.contains('received')) {
              status = ReportStatus.received;
            } else {
              status = ReportStatus.values.firstWhere(
                  (e) => e.name.toLowerCase() == s,
                  orElse: () => ReportStatus.received);
            }
          } catch (_) {}
          return Report(
            id: id,
            title: (data['title'] ?? '').toString(),
            category: category,
            location: (data['location'] ?? '').toString(),
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
            status: status,
            rawStatus: statusStr,
            createdAt: createdAt,
            description: data['description'] as String?,
            mediaPath: data['imageUrl'] as String?,
            isVideo: false,
          );
        }).toList();
        
        // Local sort (newest first) replaces Firestore orderBy to prevent index errors
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final filtered = _applyFilters(reports);

        return Scaffold(
          backgroundColor: const Color(0xFFF0F7F8),
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF064554), Color(0xFF0a6378)],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 20, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'All Reports',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search reports…',
                    hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF9E9E9E), size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF9E9E9E)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filter chips
              Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: Row(
                    children: [
                      _filterChip(
                        label: 'All',
                        selected:
                            _filterStatus == null && _filterCategory == null,
                        onTap: () => setState(() {
                          _filterStatus = null;
                          _filterCategory = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      ...ReportStatus.values.map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _filterChip(
                              label: s.label,
                              selected: _filterStatus == s,
                              color: _statusColor(s),
                              onTap: () => setState(() {
                                _filterStatus = _filterStatus == s ? null : s;
                                _filterCategory = null;
                              }),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // Count
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} report${filtered.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'No reports match your filters.',
                              style: TextStyle(
                                  color: Color(0xFFBDBDBD), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _ReportListTile(report: filtered[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? const Color(0xFF064554);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : c.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c,
          ),
        ),
      ),
    );
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.received:
        return const Color(0xFF9E9E9E);
      case ReportStatus.aiVerified:
        return const Color(0xFF2196F3);
      case ReportStatus.assignedToDept:
        return const Color(0xFFFFC107);
      case ReportStatus.resolved:
        return const Color(0xFF4CAF50);
      case ReportStatus.rejected:
        return const Color(0xFFE53935);
    }
  }
}

class _ReportListTile extends StatelessWidget {
  final Report report;

  const _ReportListTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/report-detail',
        arguments: report.id,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: report.mediaPath != null
                  ? Image.file(
                      File(report.mediaPath!),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(report.category),
                    )
                  : _iconBox(report.category),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Color(0xFF78909C)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.location,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF78909C), fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(
                      status: report.status, rawLabel: report.rawStatus, compact: true),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDate(report.createdAt),
                  style:
                      const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF90A4AE)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F7F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF064554), size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IssueCategory cat) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _catColor(cat).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_catIcon(cat), color: _catColor(cat), size: 28),
    );
  }

  Color _catColor(IssueCategory cat) {
    switch (cat) {
      case IssueCategory.pothole:
        return const Color(0xFF064554);
      case IssueCategory.garbage:
        return const Color(0xFF6D4C41);
      case IssueCategory.brokenStreetlight:
        return const Color(0xFFFB8C00);
      case IssueCategory.waterLeak:
        return const Color(0xFF0288D1);
      case IssueCategory.other:
        return const Color(0xFF757575);
    }
  }

  IconData _catIcon(IssueCategory cat) {
    switch (cat) {
      case IssueCategory.pothole:
        return Icons.warning_amber_rounded;
      case IssueCategory.garbage:
        return Icons.delete_outline_rounded;
      case IssueCategory.brokenStreetlight:
        return Icons.lightbulb_outline_rounded;
      case IssueCategory.waterLeak:
        return Icons.water_drop_outlined;
      case IssueCategory.other:
        return Icons.help_outline_rounded;
    }
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}
