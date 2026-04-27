import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report.dart';
import '../widgets/mock_map_widget.dart';
import '../widgets/status_badge.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment(String reportId) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingComment = true);
    _commentCtrl.clear();
    await context.read<ReportProvider>().addComment(reportId, text);
    setState(() => _sendingComment = false);
  }


  @override
  Widget build(BuildContext context) {
    final reportId = ModalRoute.of(context)?.settings.arguments as String?;

    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        final report = reportId != null
            ? provider.getById(reportId)
            : provider.reports.firstOrNull;

        if (report == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Report Detail'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: Text('Report not found.')),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('Report Detail',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
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
                                  style: TextStyle(
                                      color: Color(0xFFE53935)))),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context
                          .read<ReportProvider>()
                          .deleteReport(report.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFE53935), size: 18),
                        SizedBox(width: 8),
                        Text('Delete Report',
                            style: TextStyle(color: Color(0xFFE53935))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            backgroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child:
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Status Timeline ────────────────────────────────────────
              _card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Status Timeline',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const Spacer(),
                      StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTimeline(report),
                ],
              )),

              const SizedBox(height: 16),
              // ── Evidence ───────────────────────────────────────────────
              _card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report Evidence',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: report.mediaPath != null
                        ? (report.isVideo
                            ? Container(
                                height: 160,
                                color: const Color(0xFF263238),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_circle_fill_rounded,
                                          color: Colors.white, size: 48),
                                      SizedBox(height: 6),
                                      Text('Video evidence',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              )
                            : Image.file(
                                File(report.mediaPath!),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderMedia(),
                              ))
                        : _placeholderMedia(),
                  ),
                ],
              )),

              const SizedBox(height: 16),
              // ── Report Details ─────────────────────────────────────────
              _card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report Details',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 16),
                  _detailRow(
                    icon: Icons.category_outlined,
                    label: 'Issue Category',
                    value: report.category.label,
                    iconColor: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 14),
                  _detailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: report.location,
                    iconColor: const Color(0xFFE53935),
                  ),
                  if (report.latitude != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        'GPS: ${report.latitude!.toStringAsFixed(5)}, '
                        '${report.longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E)),
                      ),
                    ),
                  ],
                  if (report.description != null) ...[
                    const SizedBox(height: 14),
                    _detailRow(
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: report.description!,
                      iconColor: const Color(0xFF9E9E9E),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _detailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Submitted',
                    value: _formatDateTime(report.createdAt),
                    iconColor: const Color(0xFF9E9E9E),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MockMapWidget(
                      height: 130,
                      highlightLat: report.latitude,
                      highlightLon: report.longitude,
                    ),
                  ),
                ],
              )),

              const SizedBox(height: 16),
              // ── Updates ───────────────────────────────────────────────
              if (report.updates.isNotEmpty)
                _card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Updates (${report.updates.length})',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 12),
                    ...report.updates.reversed
                        .map(_updateTile)
                        ,
                  ],
                )),

              const SizedBox(height: 16),
              // ── Comment box ───────────────────────────────────────────
              _card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Comment / Request Update',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Write a comment or request an update…',
                        hintStyle: TextStyle(
                            color: Color(0xFFBDBDBD), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _sendingComment
                            ? null
                            : () => _sendComment(report.id),
                        icon: _sendingComment
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              )),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(Report report) {
    final steps = [
      _Step('Received', Icons.inbox_rounded, true, true,
          report.createdAt),
      _Step('AI Verified', Icons.smart_toy_outlined,
          report.status.index >= ReportStatus.aiVerified.index,
          report.status.index >= ReportStatus.aiVerified.index,
          report.updates
              .where((u) => u.message.contains('AI'))
              .firstOrNull
              ?.timestamp),
      _Step('Assigned to Dept', Icons.assignment_outlined,
          report.status.index >= ReportStatus.assignedToDept.index,
          report.status.index >= ReportStatus.assignedToDept.index,
          null),
      _Step('Resolved', Icons.check_circle_outline_rounded,
          report.status == ReportStatus.resolved,
          report.status == ReportStatus.resolved, null,
          isLast: true),
    ];

    return Column(
      children: steps.map((s) {
        final color = s.isDone
            ? (s.isLast
                ? const Color(0xFF43A047)
                : const Color(0xFF1565C0))
            : const Color(0xFFE0E0E0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        color.withOpacity(s.isDone ? 1 : 0.15),
                    shape: BoxShape.circle,
                    border: s.isDone
                        ? null
                        : Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(s.icon,
                      size: 16,
                      color: s.isDone ? Colors.white : color),
                ),
                if (!s.isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: color.withOpacity(0.3),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: s.isDone
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFFBDBDBD))),
                  if (s.date != null)
                    Text(_formatDateTime(s.date!),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                  if (!s.isLast) const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _updateTile(ReportUpdate u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: u.isOfficial
            ? const Color(0xFF1565C0).withOpacity(0.05)
            : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: u.isOfficial
              ? const Color(0xFF1565C0).withOpacity(0.15)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            u.isOfficial
                ? Icons.verified_outlined
                : Icons.person_outlined,
            size: 16,
            color: u.isOfficial
                ? const Color(0xFF1565C0)
                : const Color(0xFF9E9E9E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.isOfficial ? 'Official Update' : 'Your Comment',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: u.isOfficial
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(u.message,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF424242),
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(_formatDateTime(u.timestamp),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFBDBDBD))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _placeholderMedia() => Container(
        height: 160,
        color: const Color(0xFFECEFF1),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 40, color: Color(0xFFB0BEC5)),
              SizedBox(height: 6),
              Text('No photo attached',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
            ],
          ),
        ),
      );

  String _formatDateTime(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$min';
  }
}

class _Step {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDone;
  final DateTime? date;
  final bool isLast;

  const _Step(
    this.label,
    this.icon,
    this.isActive,
    this.isDone,
    this.date, {
    this.isLast = false,
  });
}
