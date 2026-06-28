import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/snackbar_helper.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';
import '../models/report.dart';
import '../widgets/mock_map_widget.dart';
import '../widgets/status_badge.dart';
import '../utils/status_helper.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;

    if (arg is Report) return _scaffoldForReport(arg);

    final reportId = arg as String?;

    if (reportId == null) {
      return Consumer<ReportProvider>(builder: (context, provider, _) {
        final r = provider.reports.isNotEmpty ? provider.reports.first : null;
        if (r == null) return _notFoundScaffold();
        return _scaffoldForReport(r);
      });
    }

    // Listen to Firestore document for live updates
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snap.hasData || !(snap.data?.exists ?? false))
          return _notFoundScaffold();
        final report = _reportFromDoc(snap.data!);
        return _scaffoldForReport(report);
      },
    );
  }

  Widget _notFoundScaffold() => Scaffold(
        appBar: AppBar(
          title: const Text('Report Detail'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Report not found.')),
      );

  Widget _scaffoldForReport(Report report) {
    return Consumer<ReportProvider>(builder: (context, provider, _) {
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
          title: const Text('Report Detail',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                size: 20, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Builder(
              builder: (BuildContext innerContext) {
                final canDelete = report.status == ReportStatus.received ||
                    report.status == ReportStatus.aiVerified ||
                    report.status == ReportStatus.rejected;

                return Tooltip(
                  message: canDelete ? 'Delete report' : 'Cannot Delete',
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color:
                          canDelete ? const Color(0xFFE53935) : Colors.white38,
                    ),
                    onPressed: canDelete
                        ? () => _confirmAndDelete(context, report.id)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Text('Status Timeline',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const Spacer(),
                      StatusBadge(
                          status: report.status, rawLabel: report.rawStatus),
                    ]),
                    const SizedBox(height: 16),
                    _buildTimeline(report),
                  ])),

              const SizedBox(height: 16),
              _card(
                  child: Column(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                : _mediaWidget(report.mediaPath!))
                            : _placeholderMedia()),
                  ])),

              const SizedBox(height: 16),
              _card(
                  child: Column(
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
                        iconColor: const Color(0xFF064554)),
                    const SizedBox(height: 14),
                    _detailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: report.location,
                        iconColor: const Color(0xFFE53935)),
                    if (report.latitude != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 48),
                        child: Text(
                          'GPS: ${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
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
                          iconColor: const Color(0xFF9E9E9E)),
                    ],
                    const SizedBox(height: 14),
                    _detailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Submitted',
                        value: _formatDateTime(report.createdAt),
                        iconColor: const Color(0xFF9E9E9E)),
                    const SizedBox(height: 16),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: MockMapWidget(
                            height: 130,
                            highlightLat: report.latitude,
                            highlightLon: report.longitude)),
                  ])),

              const SizedBox(height: 16),

              // ── Delete button ────────────────────────────────────────────────
              Builder(builder: (ctx) {
                final canDelete = report.status == ReportStatus.received ||
                    report.status == ReportStatus.aiVerified ||
                    report.status == ReportStatus.rejected;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color:
                            canDelete ? Colors.white : const Color(0xFF9E9E9E),
                      ),
                      label: Text(
                        canDelete ? 'Delete Report' : 'Cannot Delete',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: canDelete
                              ? Colors.white
                              : const Color(0xFF9E9E9E),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canDelete
                            ? const Color(0xFFE53935)
                            : const Color(0xFFF5F5F5),
                        disabledBackgroundColor: const Color(0xFFF5F5F5),
                        elevation: canDelete ? 2 : 0,
                        shadowColor: const Color(0xFFE53935).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: canDelete
                              ? BorderSide.none
                              : const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      onPressed: canDelete
                          ? () => _confirmAndDelete(context, report.id)
                          : null,
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _confirmAndDelete(
      BuildContext screenContext, String reportId) async {
    await showDialog<void>(
      context: screenContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              content: const Text(
                'Are you sure you want to delete this report? '
                'This action cannot be undone.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                TextButton(
                  onPressed:
                      isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w500)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('reports')
                                .doc(reportId)
                                .delete();

                            if (!mounted) return;
                            Navigator.pop(dialogContext); // close dialog
                            // ignore: use_build_context_synchronously
                            SnackBarHelper.showSuccess(
                                screenContext, 'Report deleted successfully.');
                            // ignore: use_build_context_synchronously
                            Navigator.pop(screenContext); // back to dashboard
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            Navigator.pop(dialogContext);
                            // ignore: use_build_context_synchronously
                            SnackBarHelper.showError(
                                screenContext, 'Failed to delete report: $e');
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Delete',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _mediaWidget(String path) {
    if (path.trim().toLowerCase().startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholderMedia(),
        errorWidget: (_, __, ___) => _placeholderMedia(),
      );
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholderMedia());
      }
    } catch (_) {}
    return _placeholderMedia();
  }

  Report _reportFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final title = (data['title'] ?? data['headline'] ?? '') as String;
    final description = (data['description'] ?? '') as String?;
    final rawStatus = (data['status'] ?? '').toString();
    final timestamp = data['timestamp'];
    DateTime createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is String) {
      createdAt = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    final imageUrl = (data['imageUrl'] ??
        data['mediaPath'] ??
        data['media'] ??
        '') as String?;
    final categoryRaw = (data['category'] ?? '') as String?;
    IssueCategory category = IssueCategory.other;
    if (categoryRaw != null && categoryRaw.isNotEmpty) {
      try {
        category = IssueCategory.values.firstWhere((e) =>
            e.name.toLowerCase() == categoryRaw.toString().toLowerCase());
      } catch (_) {}
    }
    final loc = (data['location'] ?? '') as String? ?? '';
    final lat = (data['latitude'] as num?)?.toDouble();
    final lon = (data['longitude'] as num?)?.toDouble();

    ReportStatus status = ReportStatus.received;
    final raw = rawStatus.toString().trim().toLowerCase();
    if (raw.contains('reject') ||
        raw.contains('invalid') ||
        raw.contains('denied'))
      status = ReportStatus.rejected;
    else if (raw.contains('resolv'))
      status = ReportStatus.resolved;
    else if (raw.contains('active') ||
        raw.contains('pending') ||
        raw.contains('in progress') ||
        raw.contains('assigned'))
      status = ReportStatus.assignedToDept;
    else if (raw.contains('ai') || raw.contains('verified'))
      status = ReportStatus.aiVerified;
    else if (raw.contains('received')) status = ReportStatus.received;

    List<ReportUpdate> updates = [];
    final rawUpdates = data['updates'] as List<dynamic>?;
    if (rawUpdates != null) {
      updates = rawUpdates.map((u) {
        try {
          return ReportUpdate.fromJson(Map<String, dynamic>.from(u as Map));
        } catch (_) {
          return ReportUpdate(message: u.toString(), timestamp: DateTime.now());
        }
      }).toList();
    }

    return Report(
      id: doc.id,
      title: title.isEmpty ? 'Report' : title,
      category: category,
      location: loc,
      latitude: lat,
      longitude: lon,
      status: status,
      createdAt: createdAt,
      description: description,
      mediaPath: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
      isVideo: (data['isVideo'] as bool?) ?? false,
      updates: updates,
    );
  }

  Widget _buildTimeline(Report report) {
    final isRejected = report.status == ReportStatus.rejected;

    final List<_Step> steps;

    if (isRejected) {
      steps = [
        _Step('Received', Icons.inbox_rounded, true, true, report.createdAt),
        _Step(
            'Rejected',
            Icons.cancel_outlined,
            true,
            true,
            report.updates
                .where((u) => u.message.toLowerCase().contains('reject'))
                .firstOrNull
                ?.timestamp,
            isLast: true,
            isRejected: true),
      ];
    } else {
      steps = [
        _Step('Received', Icons.inbox_rounded, true, true, report.createdAt),
        _Step(
            'Verified',
            Icons.smart_toy_outlined,
            report.status.index >= ReportStatus.aiVerified.index,
            report.status.index >= ReportStatus.aiVerified.index,
            report.updates
                .where((u) =>
                    u.message.toLowerCase().contains('ai') ||
                    u.message.toLowerCase().contains('verified'))
                .firstOrNull
                ?.timestamp),
        _Step(
            'Assigned',
            Icons.assignment_outlined,
            report.status.index >= ReportStatus.assignedToDept.index,
            report.status.index >= ReportStatus.assignedToDept.index,
            null),
        _Step(
            'Resolved',
            Icons.check_circle_outline_rounded,
            report.status == ReportStatus.resolved,
            report.status == ReportStatus.resolved,
            null,
            isLast: true),
      ];
    }

    return Column(
        children: steps.map((s) {
      final baseColor = s.isDone
          ? (s.isRejected
              ? const Color(0xFFE53935)
              : getStatusData(s.label).color)
          : const Color(0xFFE0E0E0);

      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(s.isDone ? 1 : 0.15),
              shape: BoxShape.circle,
              border:
                  s.isDone ? null : Border.all(color: baseColor, width: 1.5),
            ),
            child: Icon(s.icon,
                size: 16, color: s.isDone ? Colors.white : baseColor),
          ),
          if (!s.isLast)
            Container(
              width: 2,
              height: 40,
              color: baseColor.withOpacity(0.3),
            ),
        ]),
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
                        ? (s.isRejected
                            ? const Color(0xFFE53935)
                            : const Color(0xFF1A1A2E))
                        : const Color(0xFFBDBDBD),
                  )),
              if (s.isRejected && s.isDone)
                const Text('Image deemed invalid by AI',
                    style: TextStyle(fontSize: 11, color: Color(0xFFE53935))),
              if (s.date != null)
                Text(_formatDateTime(s.date!),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9E9E9E))),
              if (!s.isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ]);
    }).toList());
  }

  Widget _detailRow(
      {required IconData icon,
      required String label,
      required String value,
      required Color iconColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: iconColor)),
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
    ]);
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
              offset: const Offset(0, 2))
        ],
      ),
      child: child);

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
  final bool isRejected;

  const _Step(this.label, this.icon, this.isActive, this.isDone, this.date,
      {this.isLast = false, this.isRejected = false});
}
