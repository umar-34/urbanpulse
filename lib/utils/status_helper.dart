import 'package:flutter/material.dart';

class StatusData {
  final String label;
  final Color color;
  final IconData icon;
  const StatusData(this.label, this.color, {this.icon = Icons.info_outline_rounded});
}

StatusData getStatusData(String status) {
  final s = status.toLowerCase().trim();
  if (s.contains('reject') || s.contains('invalid') || s.contains('denied'))
    return const StatusData('Rejected', Color(0xFFE53935), icon: Icons.cancel_outlined);
  if (s.contains('resolv'))
    return const StatusData('Resolved', Color(0xFF4CAF50), icon: Icons.check_circle_outline_rounded);
  if (s.contains('ai') || s.contains('verified'))
    return const StatusData('Verified', Color(0xFF2196F3), icon: Icons.verified_outlined);
  if (s.contains('assigned') || s.contains('active') || s.contains('pending') || s.contains('in progress'))
    return const StatusData('Assigned', Color(0xFFFFC107), icon: Icons.assignment_ind_outlined);
  if (s.contains('received'))
    return const StatusData('Received', Color(0xFF9E9E9E), icon: Icons.inbox_outlined);
  // default fallback
  return StatusData(status.isNotEmpty ? status : 'Received', const Color(0xFF9E9E9E));
}
