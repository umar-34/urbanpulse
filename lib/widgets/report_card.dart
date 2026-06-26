import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// shimmer removed — simplified skeletons use static placeholders
import '../models/report.dart';
import 'status_badge.dart';
import '../utils/status_helper.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        constraints: const BoxConstraints(minHeight: 140, maxHeight: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF064554).withOpacity(0.06),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: report.mediaPath != null && !report.isVideo
                        ? _buildMediaWidget(report.mediaPath!)
                        : _iconBox(),
                  ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                height: 1.2,
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
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatusBadge(status: report.status, rawLabel: report.rawStatus, compact: true),
          ],
        ),
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _catColor(report.category).withOpacity(0.15),
            _catColor(report.category).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _catColor(report.category).withOpacity(0.2), width: 1),
      ),
      child: Icon(
        _catIcon(report.category),
        color: _catColor(report.category),
        size: 22,
      ),
    );
  }

  Color _statusColor(ReportStatus s) {
    // Use the rawStatus when possible to preserve DB string mapping
    try {
      return getStatusData(report.rawStatus).color;
    } catch (_) {
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

  Widget _buildMediaWidget(String path) {
    final p = path.trim();
    try {
      if (p.startsWith('/data/') || p.startsWith('file://')) {
        final filePath = p.startsWith('file://') ? Uri.parse(p).toFilePath() : p;
        return Image.file(
          File(filePath),
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _iconBox(),
        );
      }
      if (p.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: p,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(
            width: 42,
            height: 42,
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          errorWidget: (ctx, url, error) => _iconBox(),
        );
      }
    } catch (_) {}
    return _iconBox();
  }
}

class ReportCardSkeleton extends StatelessWidget {
  final double width;
  final double height;
  const ReportCardSkeleton({super.key, this.width = 160, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
            ],
          ),
          const Spacer(),
          Container(width: double.infinity, height: 14, color: Colors.grey.shade200),
          const SizedBox(height: 6),
          Container(width: 80, height: 12, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Container(width: 60, height: 20, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}

class ReportListTileSkeleton extends StatelessWidget {
  const ReportListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 14, color: Colors.grey.shade200),
                const SizedBox(height: 6),
                Container(width: 140, height: 12, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(width: 80, height: 18, color: Colors.grey.shade200),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 36, height: 12, color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Container(width: 18, height: 18, color: Colors.grey.shade200),
            ],
          ),
        ],
      ),
    );
  }
}
