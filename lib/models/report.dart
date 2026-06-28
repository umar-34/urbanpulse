enum ReportStatus { received, aiVerified, assignedToDept, resolved, rejected }

enum IssueCategory { pothole, garbage, brokenStreetlight, waterLeak, other }

extension IssueCategoryLabel on IssueCategory {
  String get label {
    switch (this) {
      case IssueCategory.pothole:
        return 'Pothole';
      case IssueCategory.garbage:
        return 'Garbage';
      case IssueCategory.brokenStreetlight:
        return 'Broken Streetlight';
      case IssueCategory.waterLeak:
        return 'Water Leak';
      case IssueCategory.other:
        return 'Other';
    }
  }
}

extension ReportStatusLabel on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.received:
        return 'Received';
      case ReportStatus.aiVerified:
        return 'Verified';
      case ReportStatus.assignedToDept:
        return 'Assigned';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }
}

class ReportUpdate {
  final String message;
  final DateTime timestamp;
  final bool isOfficial;

  const ReportUpdate({
    required this.message,
    required this.timestamp,
    this.isOfficial = false,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'isOfficial': isOfficial,
      };

  factory ReportUpdate.fromJson(Map<String, dynamic> json) => ReportUpdate(
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isOfficial: json['isOfficial'] as bool? ?? false,
      );
}

class Report {
  final String id;
  final String title;
  final IssueCategory category;
  final String location;
  final double? latitude;
  final double? longitude;
  final ReportStatus status;
  final String rawStatus;
  final DateTime createdAt;
  final String? description;
  final String? mediaPath;
  final bool isVideo;
  final String userId;
  final List<ReportUpdate> updates;

  Report({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    required this.status,
    this.rawStatus = 'Received',
    required this.createdAt,
    this.description,
    this.mediaPath,
    this.isVideo = false,
    this.userId = '',
    this.updates = const [],
  });

  Report copyWith({
    String? id,
    String? title,
    IssueCategory? category,
    String? location,
    double? latitude,
    double? longitude,
    ReportStatus? status,
    String? rawStatus,
    DateTime? createdAt,
    String? description,
    String? mediaPath,
    bool? isVideo,
    String? userId,
    List<ReportUpdate>? updates,
  }) =>
      Report(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        location: location ?? this.location,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        status: status ?? this.status,
        rawStatus: rawStatus ?? this.rawStatus,
        createdAt: createdAt ?? this.createdAt,
        description: description ?? this.description,
        mediaPath: mediaPath ?? this.mediaPath,
        isVideo: isVideo ?? this.isVideo,
        userId: userId ?? this.userId,
        updates: updates ?? this.updates,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
      'status': (() {
        switch (status) {
          case ReportStatus.received:
            return 'Received';
          case ReportStatus.aiVerified:
            return 'Verified';
          case ReportStatus.assignedToDept:
            return 'Active';
          case ReportStatus.resolved:
            return 'Resolved';
          case ReportStatus.rejected:
            return 'Rejected';
        }
      })(),
        'createdAt': createdAt.toIso8601String(),
        'description': description,
        'mediaPath': mediaPath,
        'isVideo': isVideo,
        'userId': userId,
        'updates': updates.map((u) => u.toJson()).toList(),
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        title: json['title'] as String,
        category: IssueCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => IssueCategory.other,
        ),
        location: json['location'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        rawStatus: (json['status'] ?? 'Received').toString(),
        status: (() {
          final raw = (json['status'] ?? '').toString().trim().toLowerCase();
          if (raw.contains('reject') || raw.contains('invalid') || raw.contains('denied')) return ReportStatus.rejected;
          if (raw.contains('resolv')) return ReportStatus.resolved;
          if (raw.contains('active') || raw.contains('pending') || raw.contains('in progress') || raw.contains('assigned')) return ReportStatus.assignedToDept;
          if (raw.contains('ai') || raw.contains('verified')) return ReportStatus.aiVerified;
          if (raw.contains('received')) return ReportStatus.received;
          try {
            return ReportStatus.values.firstWhere((e) => e.name.toLowerCase() == raw);
          } catch (_) {
            return ReportStatus.received;
          }
        })(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String?,
        mediaPath: json['mediaPath'] as String?,
        isVideo: json['isVideo'] as bool? ?? false,
        userId: (json['userId'] ?? json['uid'] ?? '').toString(),
        updates: (json['updates'] as List<dynamic>?)
                ?.map((u) => ReportUpdate.fromJson(u as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
