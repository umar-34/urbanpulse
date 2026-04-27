import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';

class ReportProvider extends ChangeNotifier {
  List<Report> _reports = [];
  bool _loaded = false;

  List<Report> get reports => List.unmodifiable(_reports);

  int get totalCount => _reports.length;
  int get activeCount =>
      _reports.where((r) => r.status != ReportStatus.resolved).length;
  int get resolvedCount =>
      _reports.where((r) => r.status == ReportStatus.resolved).length;

  // ── Bootstrap ─────────────────────────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('reports');
    if (raw == null || raw.isEmpty) {
      // First launch – seed sample data
      _reports = List.from(seedReports);
    } else {
      _reports = raw.map((s) {
        try {
          return Report.fromJson(jsonDecode(s) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<Report>().toList();
    }
    notifyListeners();
  }

  // ── Persist ────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _reports.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('reports', raw);
  }

  // ── Create ─────────────────────────────────────────────────────────────────
  Future<void> addReport(Report report) async {
    _reports.insert(0, report);
    notifyListeners();
    await _save();
  }

  // ── Update status (simulate AI pipeline) ──────────────────────────────────
  Future<void> advanceStatus(String id) async {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final r = _reports[idx];
    if (r.status == ReportStatus.resolved) return;

    final next = ReportStatus.values[r.status.index + 1];
    final newUpdate = ReportUpdate(
      message: _statusMessage(next),
      timestamp: DateTime.now(),
      isOfficial: true,
    );

    _reports[idx] = r.copyWith(
      status: next,
      updates: [...r.updates, newUpdate],
    );
    notifyListeners();
    await _save();
  }

  // ── Add comment ───────────────────────────────────────────────────────────
  Future<void> addComment(String id, String message) async {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final r = _reports[idx];
    final update = ReportUpdate(
      message: message,
      timestamp: DateTime.now(),
      isOfficial: false,
    );
    _reports[idx] = r.copyWith(updates: [...r.updates, update]);
    notifyListeners();
    await _save();
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }

  // ── Get single ────────────────────────────────────────────────────────────
  Report? getById(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  String _statusMessage(ReportStatus status) {
    switch (status) {
      case ReportStatus.received:
        return 'Report received and queued for AI verification.';
      case ReportStatus.aiVerified:
        return 'AI has verified the issue. Forwarding to department.';
      case ReportStatus.assignedToDept:
        return 'Report assigned to the relevant department. Crew will be dispatched soon.';
      case ReportStatus.resolved:
        return 'Issue has been resolved. Thank you for your contribution!';
    }
  }
}
