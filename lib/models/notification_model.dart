import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String? reportId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.userId,
    this.reportId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    DateTime ts = DateTime.now();
    final rawTs = data['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    }

    return AppNotification(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      reportId: data['reportId'] as String?,
      title: (data['title'] as String?) ?? 'Notification',
      body: (data['body'] as String?) ?? '',
      timestamp: ts,
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'reportId': reportId,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      reportId: reportId,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
