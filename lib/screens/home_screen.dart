import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Quick report grid will be shown inline below
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/report_provider.dart';
import '../widgets/report_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasNotifications = true;
  String headerLocation = 'Locating...';

  @override
  void initState() {
    super.initState();
    fetchHeaderLocation();
  }

  Future<void> fetchHeaderLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => headerLocation = 'Location disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission interactively
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => headerLocation = 'Location disabled');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      try {
        final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (places.isNotEmpty) {
          final p = places.first;
          final sub = (p.subLocality ?? '').trim();
          final city = (p.locality ?? '').trim();
          if (sub.isNotEmpty && city.isNotEmpty) {
            setState(() => headerLocation = '$sub, $city');
            return;
          }
          if (city.isNotEmpty) {
            setState(() => headerLocation = city);
            return;
          }
        }
      } catch (_) {
        // ignore geocoding errors
      }

      setState(() => headerLocation = '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}');
    } catch (_) {
      setState(() => headerLocation = 'Location disabled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        final reports = provider.reports;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: Colors.white,
                floating: true,
                snap: true,
                elevation: 0,
                titleSpacing: 0,
                // increase toolbar height so header content has breathing room
                toolbarHeight: 92,
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF1565C0),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome,',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'John Doe',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              if (headerLocation == 'Location disabled' || headerLocation == 'Locating...') {
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
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  headerLocation,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
                        onTap: () =>
                            setState(() => _hasNotifications = false),
                        child: Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Color(0xFF1A1A2E),
                                size: 22,
                              ),
                            ),
                            if (_hasNotifications)
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
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: const Color(0xFFEEEEEE)),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats
                      _buildStatsRow(provider),
                      const SizedBox(height: 24),

                      // Active Reports header
                      Row(
                        children: [
                          const Text(
                            'Active Reports',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reports carousel
                      if (reports.isEmpty)
                        Container(
                          height: 130,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  size: 36, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              const Text(
                                'No reports yet. Tap + to create one.',
                                style: TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: reports.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return ReportCard(
                                report: reports[index],
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/report-detail',
                                  arguments: reports[index].id,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Quick Report section
                      const Text(
                        'Quick Report',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          padding: EdgeInsets.zero,
                          // Wider aspect ratio reduces tile height so two rows fit within 240px
                          childAspectRatio: 1.4,
                          children: [
                            _quickCard(context, 'Pothole', Icons.warning_amber_rounded, 'pothole'),
                            _quickCard(context, 'Garbage', Icons.delete_outline, 'garbage'),
                            _quickCard(context, 'Streetlight', Icons.lightbulb_outline, 'brokenStreetlight'),
                            _quickCard(context, 'Water Leak', Icons.water_drop_outlined, 'waterLeak'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
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

  Widget _quickCard(BuildContext context, String label, IconData icon, String arg) {
    final tint = const Color(0xFF1565C0).withOpacity(0.08);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/create-report', arguments: arg),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ReportProvider provider) {
    return Row(
      children: [
        _buildStatCard(
            '${provider.totalCount}', 'Total\nReports', const Color(0xFF1565C0)),
        const SizedBox(width: 12),
        _buildStatCard(
            '${provider.activeCount}', 'In\nProgress', const Color(0xFFFB8C00)),
        const SizedBox(width: 12),
        _buildStatCard(
            '${provider.resolvedCount}', 'Resolved', const Color(0xFF43A047)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FAB removed from HomeScreen
}
