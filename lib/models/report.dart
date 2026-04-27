enum ReportStatus { received, aiVerified, assignedToDept, resolved }

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
        return 'AI Verified';
      case ReportStatus.assignedToDept:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
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
  final DateTime createdAt;
  final String? description;
  final String? mediaPath;
  final bool isVideo;
  final List<ReportUpdate> updates;

  Report({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
    this.description,
    this.mediaPath,
    this.isVideo = false,
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
    DateTime? createdAt,
    String? description,
    String? mediaPath,
    bool? isVideo,
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
        createdAt: createdAt ?? this.createdAt,
        description: description ?? this.description,
        mediaPath: mediaPath ?? this.mediaPath,
        isVideo: isVideo ?? this.isVideo,
        updates: updates ?? this.updates,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
        'mediaPath': mediaPath,
        'isVideo': isVideo,
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
        status: ReportStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ReportStatus.received,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String?,
        mediaPath: json['mediaPath'] as String?,
        isVideo: json['isVideo'] as bool? ?? false,
        updates: (json['updates'] as List<dynamic>?)
                ?.map((u) => ReportUpdate.fromJson(u as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ── Seed data ──────────────────────────────────────────────────────────────
final List<Report> seedReports = [
  Report(
    id: 'seed-1',
    title: 'Pothole',
    category: IssueCategory.pothole,
    location: 'Main St., Islamabad',
    latitude: 33.7215,
    longitude: 73.0433,
    status: ReportStatus.received,
    createdAt: DateTime(2024, 6, 6),
    description: 'Large pothole causing traffic hazard near the intersection.',
    updates: [
      ReportUpdate(
        message: 'Report received and queued for AI verification.',
        timestamp: DateTime(2024, 6, 6, 9, 0),
        isOfficial: true,
      ),
    ],
  ),
  Report(
    id: 'seed-2',
    title: 'Garbage',
    category: IssueCategory.garbage,
    location: 'Park Avenue, Islamabad',
    latitude: 33.7200,
    longitude: 73.0450,
    status: ReportStatus.aiVerified,
    createdAt: DateTime(2024, 6, 5),
    description: 'Illegal dumping of garbage near the park entrance.',
    updates: [
      ReportUpdate(
        message: 'AI has verified the issue. Assigned to sanitation dept.',
        timestamp: DateTime(2024, 6, 5, 14, 0),
        isOfficial: true,
      ),
    ],
  ),
  Report(
    id: 'seed-3',
    title: 'Broken Streetlight',
    category: IssueCategory.brokenStreetlight,
    location: 'Blue Area, Islamabad',
    latitude: 33.7295,
    longitude: 73.0931,
    status: ReportStatus.resolved,
    createdAt: DateTime(2024, 6, 4),
    description: 'Broken streetlight creating safety concern at night.',
    updates: [
      ReportUpdate(
        message: 'Crew dispatched and streetlight replaced.',
        timestamp: DateTime(2024, 6, 5, 10, 0),
        isOfficial: true,
      ),
      ReportUpdate(
        message: 'Issue resolved! Thank you for your report.',
        timestamp: DateTime(2024, 6, 5, 16, 0),
        isOfficial: true,
      ),
    ],
  ),
  Report(
    id: 'seed-4',
    title: 'Water Leak',
    category: IssueCategory.waterLeak,
    location: 'F-10 Sector, Islamabad',
    latitude: 33.7050,
    longitude: 73.0350,
    status: ReportStatus.assignedToDept,
    createdAt: DateTime(2024, 6, 3),
    description: 'Water pipe leaking onto the sidewalk causing flooding.',
    updates: [],
  ),
];
