import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized service for updating a report's status and writing
/// a paired notification to the [notifications] collection atomically.
///
/// Call this anywhere in the app where you advance a report's status.
class NotificationService {
  static final _db = FirebaseFirestore.instance;

  /// Updates [status] on the given report document and immediately writes a
  /// corresponding notification for the report owner.
  ///
  /// - [reportId]     Firestore document ID of the report.
  /// - [reportOwnerId] UID of the citizen who created the report.
  /// - [reportTitle]  Human-readable title of the report (for the notification body).
  /// - [newStatus]    The new status string (e.g. "AI Verified", "Assigned to Department", "Resolved").
  /// - [extraFields]  Any additional fields to merge into the report document (optional).
  static Future<void> updateReportStatus({
    required String reportId,
    required String reportOwnerId,
    required String reportTitle,
    required String newStatus,
    Map<String, dynamic>? extraFields,
  }) async {
    final batch = _db.batch();

    // ── 1. Update the report document ────────────────────────────────────────
    final reportRef = _db.collection('reports').doc(reportId);
    batch.update(reportRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      ...?extraFields,
    });

    // ── 2. Write the paired notification ─────────────────────────────────────
    final notifRef = _db.collection('notifications').doc();
    batch.set(notifRef, {
      'userId': reportOwnerId,
      'reportId': reportId,
      'title': 'Report Status Updated',
      'body': 'Your report "$reportTitle" is now $newStatus.',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  /// Convenience overload: writes a notification with a custom title and body
  /// without necessarily changing the status field (e.g. "Report Received" on submit).
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? reportId,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'reportId': reportId,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
