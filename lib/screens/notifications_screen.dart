import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // ── Relative time formatter ─────────────────────────────────────────────
  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── Mark a single notification as read ─────────────────────────────────
  Future<void> _markRead(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
    } catch (_) {}
  }

  // ── Mark all notifications as read ─────────────────────────────────────
  Future<void> _markAllRead(List<AppNotification> unread) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final n in unread) {
      batch.update(
        FirebaseFirestore.instance.collection('notifications').doc(n.id),
        {'isRead': true},
      );
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (user != null)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snap) {
                final hasUnread =
                    snap.hasData && snap.data!.docs.isNotEmpty;
                if (!hasUnread) return const SizedBox.shrink();
                final unread = snap.data!.docs
                    .map((d) => AppNotification.fromMap(d.id, d.data()))
                    .toList();
                return TextButton.icon(
                  onPressed: () => _markAllRead(unread),
                  icon: const Icon(Icons.done_all_rounded,
                      color: Colors.white70, size: 18),
                  label: const Text(
                    'Mark all read',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: user == null
          ? _emptyState('Sign in to see your notifications')
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                // ── Loading ────────────────────────────────────────────────
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF064554),
                      strokeWidth: 2.5,
                    ),
                  );
                }

                // ── Error ──────────────────────────────────────────────────
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Something went wrong.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                  );
                }

                // ── Empty ──────────────────────────────────────────────────
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _emptyState('No notifications yet');
                }

                // ── List ───────────────────────────────────────────────────
                final notifications = docs
                    .map((d) => AppNotification.fromMap(d.id, d.data()))
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _NotificationTile(
                      notification: n,
                      onTap: () {
                        if (!n.isRead) _markRead(n.id);
                        if (n.reportId != null) {
                          Navigator.pushNamed(
                            context,
                            '/report-detail',
                            arguments: n.reportId,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8EFF9), Color(0xFFD0E4F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: Color(0xFF90A4AE),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF455A64),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll be notified when there are updates\non your reports.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF90A4AE),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  static IconData _iconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('verif')) return Icons.verified_rounded;
    if (t.contains('resolv')) return Icons.check_circle_rounded;
    if (t.contains('assign')) return Icons.assignment_ind_rounded;
    if (t.contains('reject')) return Icons.cancel_rounded;
    if (t.contains('update')) return Icons.update_rounded;
    return Icons.notifications_rounded;
  }

  static Color _colorForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('verif')) return const Color(0xFF064554);
    if (t.contains('resolv')) return const Color(0xFF2E7D32);
    if (t.contains('assign')) return const Color(0xFFF57F17);
    if (t.contains('reject')) return const Color(0xFFC62828);
    if (t.contains('update')) return const Color(0xFF6A1B9A);
    return const Color(0xFF064554);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final accentColor = _colorForTitle(notification.title);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFE0F0F4)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? const Color(0xFF064554).withOpacity(0.2)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isUnread ? 0.06 : 0.04),
              blurRadius: isUnread ? 12 : 6,
              spreadRadius: isUnread ? 1 : 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Leading Icon ─────────────────────────────────────────────
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: accentColor.withOpacity(0.2), width: 1),
              ),
              child: Icon(
                _iconForTitle(notification.title),
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF546E7A),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: const Color(0xFF90A4AE),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        NotificationsScreen._relativeTime(
                            notification.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF90A4AE),
                        ),
                      ),
                      if (notification.reportId != null) ...[
                        const Spacer(),
                        Text(
                          'View report →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
