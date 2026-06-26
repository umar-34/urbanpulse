import 'package:flutter/material.dart';
import '../models/report.dart';
import '../utils/status_helper.dart';

class StatusBadge extends StatelessWidget {
  final ReportStatus? status;
  final String? rawLabel;
  final bool compact;

  const StatusBadge({super.key, this.status, this.rawLabel, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final source = (rawLabel != null && rawLabel!.trim().isNotEmpty) ? rawLabel! : (status != null ? status!.label : 'Received');
    final data = getStatusData(source);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color.withOpacity(0.25)),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: data.color,
        ),
      ),
    );
  }
}
