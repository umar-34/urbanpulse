import 'package:flutter/material.dart';
import '../models/report.dart';

class StatusBadge extends StatelessWidget {
  final ReportStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  Color get _color {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
