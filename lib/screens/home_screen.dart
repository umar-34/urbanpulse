import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/report.dart';
// Quick report grid will be shown inline below
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/report_provider.dart';
import 'create_report_screen.dart';
import '../widgets/report_card.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String headerLocation = 'Locating...';
  String? _displayName;
  String? _email;

  @override
  void initState() {
    super.initState();
    fetchHeaderLocation();
    _loadUserProfile();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _displayName = null;
          _email = null;
        });
        return;
      }
      _email = user.email;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final first = (data?['firstName'] ?? '').toString().trim();
        final last = (data?['lastName'] ?? '').toString().trim();
        if (first.isNotEmpty || last.isNotEmpty) {
          setState(() => _displayName = ('$first $last').trim());
          return;
        }
      }
      setState(() => _displayName = _email ?? 'Guest');
    } catch (e) {
      // ignore errors and fallback to defaults
      setState(() => _displayName = _email ?? 'Guest');
    }
  }

  Future<void> fetchHeaderLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => headerLocation = 'Location disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission interactively
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => headerLocation = 'Location disabled');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );

      try {
        final places =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (places.isNotEmpty) {
          final p = places.first;
          final sub = (p.subLocality ?? '').trim();
          final city = (p.locality ?? '').trim();
          if (sub.isNotEmpty && city.isNotEmpty) {
            if (!mounted) return;
            setState(() => headerLocation = '$sub, $city');
            return;
          }
          if (city.isNotEmpty) {
            if (!mounted) return;
            setState(() => headerLocation = city);
            return;
          }
        }
      } catch (_) {
        // ignore geocoding errors
      }

      if (!mounted) return;
      setState(() => headerLocation =
          '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}');
    } catch (_) {
      if (!mounted) return;
      setState(() => headerLocation = 'Location disabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
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
                pinned: true,
                elevation: 0,
                titleSpacing: 0,
                automaticallyImplyLeading: false,
                // increase toolbar height so header content has breathing room
                toolbarHeight: 92,
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseAuth.instance.currentUser == null
                              ? const Stream.empty()
                              : FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .snapshots(),
                          builder: (context, snap) {
                            // keep a stable size so header doesn't jump
                            const double size = 38;

                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF064554).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            final Map<String, dynamic>? userData =
                                snap.data?.data();
                            final String? imgPath =
                                userData?['profileImageUrl'] as String?;

                            if (imgPath != null &&
                                imgPath.isNotEmpty &&
                                File(imgPath).existsSync()) {
                              return Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF064554).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: size / 2,
                                  backgroundImage: FileImage(File(imgPath)),
                                  backgroundColor: Colors.transparent,
                                ),
                              );
                            }

                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: const Color(0xFF064554).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF064554),
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseAuth.instance.currentUser == null
                                ? const Stream.empty()
                                : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(_displayName ?? 'Guest',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ));
                              }

                              final displayName =
                                  snapshot.data?.data()?['name']?.toString() ??
                                      _displayName ??
                                      'User';
                              return Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              if (headerLocation == 'Location disabled' ||
                                  headerLocation == 'Locating...') {
                                fetchHeaderLocation();
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  headerLocation == 'Location disabled'
                                      ? Icons.location_off
                                      : (headerLocation == 'Locating...'
                                          ? Icons.location_searching
                                          : Icons.location_on),
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  headerLocation,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('notifications')
                              .where('userId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser?.uid ??
                                          '')
                              .where('isRead', isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final hasUnread = snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty;
                            return Stack(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                if (hasUnread)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE53935),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Featured Image Banner ──────────────────────────
                        _buildImageBanner(),
                        const SizedBox(height: 20),

                        // Stats
                        _buildStatsRow(provider),
                        const SizedBox(height: 24),

                        // Active Reports header
                        Row(
                          children: [
                            const Text(
                              'Active Reports',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/all-reports'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'See all',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF064554),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Reports carousel (from Firestore)
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('reports')
                                .where('userId',
                                    isEqualTo:
                                        FirebaseAuth.instance.currentUser?.uid)
                                .snapshots(),
                            builder: (context, snap) {
                              if (snap.hasError) {
                                return SizedBox(
                                  height: 130,
                                  child: Center(
                                      child: Text('Error: ${snap.error}',
                                          style: const TextStyle(
                                              color: Colors.red))),
                                );
                              }

                              // If we already have data, show it immediately.
                              if (snap.hasData) {
                                final docs = snap.data!.docs;
                                // Local filtering and sorting to bypass Firestore index errors
                                var reports =
                                    docs.map((d) => _reportFromDoc(d)).toList();

                                reports = reports
                                    .where((r) =>
                                        r.status != ReportStatus.resolved &&
                                        r.status != ReportStatus.rejected)
                                    .toList();
                                reports.sort((a, b) =>
                                    b.createdAt.compareTo(a.createdAt));

                                if (reports.isEmpty) {
                                  return _buildEmptyState(context);
                                }

                                return SizedBox(
                                  height: 160,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: reports.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 14),
                                    itemBuilder: (context, index) {
                                      final r = reports[index];
                                      return ReportCard(
                                        report: r,
                                        onTap: () => Navigator.pushNamed(
                                            context, '/report-detail',
                                            arguments: r.id),
                                      );
                                    },
                                  ),
                                );
                              }

                              // While waiting for initial data, show a loader. Do not override existing data.
                              if (snap.connectionState ==
                                      ConnectionState.waiting &&
                                  !snap.hasData) {
                                return SizedBox(
                                  height: 160,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 3,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 14),
                                    itemBuilder: (context, index) {
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          width: 260,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration:
                                                          const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle)),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                      width: 100,
                                                      height: 16,
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4))),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              Container(
                                                  width: double.infinity,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4))),
                                              const SizedBox(height: 8),
                                              Container(
                                                  width: 160,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4))),
                                              const Spacer(),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                      width: 90,
                                                      height: 26,
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      12))),
                                                  Container(
                                                      width: 60,
                                                      height: 14,
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4))),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }

                              // Fallback: show empty state if we reach here with no data
                              return _buildEmptyState(context);
                            }),
                        const SizedBox(height: 24),

                        // Quick Report section
                        const Text(
                          'Quick Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          padding: EdgeInsets.zero,
                          childAspectRatio: 1.25,
                          children: const [
                            QuickReportTile(
                              label: 'Pothole',
                              icon: Icons.warning_amber_rounded,
                              arg: 'pothole',
                            ),
                            QuickReportTile(
                              label: 'Garbage',
                              icon: Icons.delete_outline,
                              arg: 'garbage',
                            ),
                            QuickReportTile(
                              label: 'Streetlight',
                              icon: Icons.lightbulb_outline,
                              arg: 'brokenStreetlight',
                            ),
                            QuickReportTile(
                              label: 'Water Leak',
                              icon: Icons.water_drop_outlined,
                              arg: 'waterLeak',
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // FAB removed from HomeScreen; moved to MyReportsScreen
        );
      },
    );
  }



  Report _reportFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final id = doc.id;
    final title = (data['title'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final categoryStr = (data['category'] ?? '').toString().trim();
    final statusStr = (data['status'] ?? '').toString().trim();
    final timestamp = data['timestamp'] as Timestamp?;
    final createdAt = timestamp != null ? timestamp.toDate() : DateTime.now();
    IssueCategory category = IssueCategory.other;
    try {
      final cs = categoryStr.toLowerCase();
      category = IssueCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == cs || e.label.toLowerCase() == cs);
    } catch (_) {}
    ReportStatus status = ReportStatus.received;
    try {
      final s = statusStr.toLowerCase();
      if (s.contains('reject') ||
          s.contains('invalid') ||
          s.contains('denied')) {
        status = ReportStatus.rejected;
      } else if (s.contains('resolv')) {
        status = ReportStatus.resolved;
      } else if (s.contains('active') ||
          s.contains('pending') ||
          s.contains('in progress') ||
          s.contains('assigned')) {
        status = ReportStatus.assignedToDept;
      } else if (s.contains('ai') || s.contains('verified')) {
        status = ReportStatus.aiVerified;
      } else if (s.contains('received')) {
        status = ReportStatus.received;
      } else {
        status = ReportStatus.values.firstWhere(
            (e) => e.name.toLowerCase() == s,
            orElse: () => ReportStatus.received);
      }
    } catch (_) {}

    return Report(
      id: id,
      title: title,
      category: category,
      location: location,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: status,
      rawStatus: statusStr,
      createdAt: createdAt,
      description: data['description'] as String?,
      mediaPath: data['imageUrl'] as String?,
      isVideo: false,
    );
  }

  // ── Featured Image Banner ───────────────────────────────────────────────
  Widget _buildImageBanner() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              'assets/images/home_image.png',
              fit: BoxFit.cover,
            ),
            // Dark gradient overlay for text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Color(0x00000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
            // Title text
            Positioned(
              bottom: 24,
              left: 20,
              right: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Urban Reporting Hub',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report. Track. Resolve.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ───────────────────────────────────────────────────────────
  Widget _buildStatsRow(ReportProvider provider) {
    final stream = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        int total = 0;
        int inProgress = 0;
        int resolved = 0;
        if (snap.hasData && snap.data != null) {
          final docs = snap.data!.docs;
          total = docs.length;
          inProgress = docs.where((doc) {
            final s =
                (doc.data()['status'] ?? '').toString().trim().toLowerCase();
            return s.contains('received') ||
                s.contains('ai') ||
                s.contains('verified') ||
                s.contains('active') ||
                s.contains('pending') ||
                s.contains('in progress') ||
                s.contains('assigned');
          }).length;
          resolved = docs.where((doc) {
            final s =
                (doc.data()['status'] ?? '').toString().trim().toLowerCase();
            return s.contains('resolv');
          }).length;
        }

        return Row(
          children: [
            _buildGradientStatCard(
              value: '$total',
              label: 'Issues\nreported',
              gradientColors: const [Color(0xFFE8365D), Color(0xFFFF6F91)],
              badgeIcon: Icons.campaign_rounded,
            ),
            const SizedBox(width: 10),
            _buildGradientStatCard(
              value: '$inProgress',
              label: 'Issues in\nprogress',
              gradientColors: const [Color(0xFF2979FF), Color(0xFF64B5F6)],
              badgeIcon: Icons.rocket_launch_rounded,
            ),
            const SizedBox(width: 10),
            _buildGradientStatCard(
              value: '$resolved',
              label: 'Issues\nfixed',
              gradientColors: const [Color(0xFF7C3AED), Color(0xFFB57BEE)],
              badgeIcon: Icons.thumb_up_alt_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGradientStatCard({
    required String value,
    required String label,
    required List<Color> gradientColors,
    required IconData badgeIcon,
  }) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Number + label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.3,
                  ),
                ),
              ],
            ),
            // Circular icon badge
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badgeIcon,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF064554).withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateReportScreen()),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF064554).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.assignment_add,
                  color: Color(0xFF064554), size: 26),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Reports',
            style: TextStyle(
              color: Color(0xFF455A64),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the icon to file a new report',
            style: TextStyle(
              color: Color(0xFF90A4AE),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickReportTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final String arg;

  const QuickReportTile({
    super.key,
    required this.label,
    required this.icon,
    required this.arg,
  });

  @override
  State<QuickReportTile> createState() => _QuickReportTileState();
}

class _QuickReportTileState extends State<QuickReportTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors;
    switch (widget.arg) {
      case 'garbage':
        gradientColors = [const Color(0xFFEF5350), const Color(0xFFC62828)];
        break;
      case 'brokenStreetlight':
        gradientColors = [const Color(0xFFFFCA28), const Color(0xFFF57F17)];
        break;
      case 'waterLeak':
        gradientColors = [const Color(0xFF29B6F6), const Color(0xFF0277BD)];
        break;
      case 'pothole':
      default:
        gradientColors = [const Color(0xFF5C6BC0), const Color(0xFF283593)];
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.pushNamed(context, '/create-report', arguments: widget.arg);
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    widget.icon,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glassmorphic Icon Container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(widget.icon, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
