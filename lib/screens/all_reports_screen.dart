import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report.dart';
import '../widgets/status_badge.dart';

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
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        final filtered = _applyFilters(provider.reports);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'All Reports',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFEEEEEE)),
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
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 12),
                  child: Row(
                    children: [
                      _filterChip(
                        label: 'All',
                        selected: _filterStatus == null &&
                            _filterCategory == null,
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
                                _filterStatus =
                                    _filterStatus == s ? null : s;
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
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
    final c = color ?? const Color(0xFF1565C0);
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
        return const Color(0xFF1565C0);
      case ReportStatus.assignedToDept:
        return const Color(0xFFFB8C00);
      case ReportStatus.resolved:
        return const Color(0xFF43A047);
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: report.mediaPath != null
                  ? Image.file(
                      File(report.mediaPath!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(report.category),
                    )
                  : _iconBox(report.category),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          report.location,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9E9E9E)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: report.status),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(report.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFBDBDBD)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBDBDBD), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IssueCategory cat) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _catColor(cat).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_catIcon(cat), color: _catColor(cat), size: 26),
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

  String _formatDate(DateTime d) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}
