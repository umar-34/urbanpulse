import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> updateReportStatus({
    required String reportId,
    required String reportOwnerId,
    required String reportTitle,
    required String newStatus,
    Map<String, dynamic>? extraFields,
  }) async {
    final batch = _db.batch();

    final reportRef = _db.collection('reports').doc(reportId);
    batch.update(reportRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      ...?extraFields,
    });

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
