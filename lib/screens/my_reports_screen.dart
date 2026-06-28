import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report.dart';
import '../widgets/status_badge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

Report _reportFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  final id = doc.id;
  final title = (data['title'] ?? '').toString();
  final location = (data['location'] ?? '').toString();
  final categoryStr = (data['category'] ?? '').toString().trim();
  final statusStr = (data['status'] ?? '').toString().trim();
  final timestamp = data['timestamp'] as Timestamp?;
  final createdAt = timestamp != null ? timestamp.toDate() : DateTime.now();
  IssueCategory category = IssueCategory.other;
  try {
    final cs = categoryStr.toLowerCase();
    category = IssueCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == cs || e.label.toLowerCase() == cs);
  } catch (_) {}
  ReportStatus status = ReportStatus.received;
  try {
    final s = statusStr.toLowerCase();
    if (s.contains('reject') || s.contains('invalid') || s.contains('denied')) {
      status = ReportStatus.rejected;
    } else if (s.contains('resolv')) {
      status = ReportStatus.resolved;
    } else if (s.contains('active') ||
        s.contains('pending') ||
        s.contains('in progress') ||
        s.contains('assigned')) {
      status = ReportStatus.assignedToDept;
    } else if (s.contains('ai') || s.contains('verified')) {
      status = ReportStatus.aiVerified;
    } else if (s.contains('received')) {
      status = ReportStatus.received;
    } else {
      status = ReportStatus.values.firstWhere((e) => e.name.toLowerCase() == s,
          orElse: () => ReportStatus.received);
    }
  } catch (_) {}

  return Report(
    id: id,
    title: title,
    category: category,
    location: location,
    latitude: (data['latitude'] as num?)?.toDouble(),
    longitude: (data['longitude'] as num?)?.toDouble(),
    status: status,
    rawStatus: statusStr,
    createdAt: createdAt,
    description: data['description'] as String?,
    mediaPath: data['imageUrl'] as String?,
    isVideo: false,
  );
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedStatus = 'All';
  int allCount = 0;
  int activeCount = 0;
  int resolvedCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
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
            title: const Text('My Reports',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/create-report'),
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: Colors.white),
                  label: const Text('New',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              onTap: (index) => setState(() {
                _tabController.index = index;
                selectedStatus =
                    index == 0 ? 'All' : (index == 1 ? 'Active' : 'Resolved');
              }),
              tabs: [
                Tab(text: 'All ($allCount)'),
                Tab(text: 'Active ($activeCount)'),
                Tab(text: 'Resolved ($resolvedCount)'),
              ],
            ),
          ),
          body: Builder(
            builder: (context) {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      "You haven't submitted any reports yet. Click the button below to submit a new report.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 15),
                    ),
                  ),
                );
              }

              final stream = FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: userId) // fixed
                  .snapshots();

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    // ignore: avoid_print
                    print('Firestore stream error: ${snap.error}');
                    return const Center(child: Text('Something went wrong'));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Color(0xFF064554)),
                        ),
                      ),
                    );
                  }

                  final docs = snap.data?.docs ?? [];

                  final allReports = docs.map((d) => _reportFromDoc(d)).toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  final newAll = allReports.length;
                  final newActive = allReports
                      .where((r) =>
                          r.status != ReportStatus.resolved &&
                          r.status != ReportStatus.rejected)
                      .length;
                  final newResolved = allReports
                      .where((r) => r.status == ReportStatus.resolved)
                      .length;

                  if (newAll != allCount ||
                      newActive != activeCount ||
                      newResolved != resolvedCount) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        allCount = newAll;
                        activeCount = newActive;
                        resolvedCount = newResolved;
                      });
                    });
                  }

                  final filtered = allReports.where((r) {
                    if (_tabController.index == 0) return true; // All
                    if (_tabController.index == 1) {
                      return r.status != ReportStatus.resolved &&
                          r.status != ReportStatus.rejected;
                    }
                    return r.status == ReportStatus.resolved; // Resolved
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 60, color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            const Text(
                              "You haven't submitted any reports yet. "
                              'Click the button below to submit a new report.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFFBDBDBD), fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      return _ReportTile(report: filtered[i]);
                    },
                  );
                },
              );
            },
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/create-report'),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF064554).withOpacity(0.28),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: Color(0xFF064554),
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Report Issue',
                          style: TextStyle(
                            color: Color(0xFF064554),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Report report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/report-detail',
          arguments: report.id),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.62),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF064554).withOpacity(0.14),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: report.mediaPath != null
                      ? _buildThumbnail(report)
                      : _iconBox(report.category),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                              letterSpacing: 0.2)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: Color(0xFF78909C)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(report.location,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF78909C), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(
                          status: report.status,
                          rawLabel: report.rawStatus,
                          compact: true),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_fmt(report.createdAt),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF90A4AE))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064554).withOpacity(0.10),
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
        ),
      ),
    );
  }

  Widget _iconBox(IssueCategory cat) {
    final color = _catColor(cat);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_catIcon(cat), color: color, size: 28),
    );
  }

  ///   â€¢ Local file paths                â†’ Image.file
  ///   â€¢ Video reports                   â†’ play-button overlay
  Widget _buildThumbnail(Report report) {
    if (report.isVideo) {
      return Container(
        width: 64,
        height: 64,
        color: const Color(0xFF263238),
        child: const Icon(Icons.play_circle_fill_rounded,
            color: Colors.white, size: 28),
      );
    }
    final path = report.mediaPath!;
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) => _iconBox(report.category),
        errorWidget: (_, __, ___) => _iconBox(report.category),
      );
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _iconBox(report.category));
      }
    } catch (_) {}
    return _iconBox(report.category);
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

  String _fmt(DateTime d) {
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
