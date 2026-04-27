import 'dart:io';
import 'package:flutter/material.dart';
import '../models/report.dart';
import 'status_badge.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Media thumbnail or icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: report.mediaPath != null && !report.isVideo
                      ? Image.file(
                          File(report.mediaPath!),
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _iconBox(),
                        )
                      : _iconBox(),
                ),
                // Status dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: _statusColor(report.status),
                      shape: BoxShape.circle),
                ),
              ],
            ),
            const Spacer(),
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
                    size: 11, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9E9E9E)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatusBadge(status: report.status, compact: true),
          ],
        ),
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _catColor(report.category).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _catIcon(report.category),
        color: _catColor(report.category),
        size: 20,
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
}
