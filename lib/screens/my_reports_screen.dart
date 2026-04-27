import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report.dart';
import '../widgets/status_badge.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Report> _filtered(List<Report> all, int tab) {
    switch (tab) {
      case 0:
        return all;
      case 1:
        return all
            .where((r) => r.status != ReportStatus.resolved)
            .toList();
      case 2:
        return all
            .where((r) => r.status == ReportStatus.resolved)
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('My Reports',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/create-report'),
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: Color(0xFF1565C0)),
                  label: const Text('New',
                      style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1565C0),
              unselectedLabelColor: const Color(0xFF9E9E9E),
              indicatorColor: const Color(0xFF1565C0),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              onTap: (_) => setState(() {}),
              tabs: [
                Tab(text: 'All (${provider.totalCount})'),
                Tab(text: 'Active (${provider.activeCount})'),
                Tab(text: 'Resolved (${provider.resolvedCount})'),
              ],
            ),
          ),
          body: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final reports = _filtered(
                  provider.reports, _tabController.index);
              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 60, color: Colors.grey.shade200),
                      const SizedBox(height: 12),
                      const Text('No reports here',
                          style: TextStyle(
                              color: Color(0xFFBDBDBD), fontSize: 15)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/create-report'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _ReportTile(report: reports[i]),
              );
            },
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/create-report'),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF43A047).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Report Issue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
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
    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Report'),
            content: const Text(
                'Are you sure you want to delete this report?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Color(0xFFE53935)))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<ReportProvider>().deleteReport(report.id);
      },
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, '/report-detail',
                arguments: report.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: report.mediaPath != null
                    ? (report.isVideo
                        ? Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFF263238),
                            child: const Icon(Icons.play_circle_fill_rounded,
                                color: Colors.white, size: 26),
                          )
                        : Image.file(
                            File(report.mediaPath!),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _iconBox(report.category),
                          ))
                    : _iconBox(report.category),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(report.location,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9E9E9E)),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: report.status, compact: true),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(report.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFBDBDBD))),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFBDBDBD), size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IssueCategory cat) {
    final color = _catColor(cat);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_catIcon(cat), color: color, size: 26),
    );
  }

  Color _catColor(IssueCategory cat) {
    switch (cat) {
      case IssueCategory.pothole:
        return const Color(0xFF1565C0);
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
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }
}
