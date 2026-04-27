import 'package:flutter/material.dart';
import '../models/report.dart';

class MockMapWidget extends StatelessWidget {
  final double height;
  final List<Report> reports;
  final double? highlightLat;
  final double? highlightLon;

  const MockMapWidget({
    super.key,
    required this.height,
    this.reports = const [],
    this.highlightLat,
    this.highlightLon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map base
            CustomPaint(
              size: Size(double.infinity, height),
              painter: _MapPainter(),
            ),

            // Report pins (up to 6)
            ...reports.take(6).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              // Distribute pins across the map
              final positions = [
                [0.22, 0.35],
                [0.55, 0.25],
                [0.70, 0.60],
                [0.35, 0.65],
                [0.80, 0.35],
                [0.15, 0.70],
              ];
              final pos = positions[idx % positions.length];
              return _PinOverlay(
                xRatio: pos[0],
                yRatio: pos[1],
                color: _statusColor(r.status),
                icon: _catIcon(r.category),
                height: height,
              );
            }),

            // Highlighted GPS location (red pulsing dot)
            if (highlightLat != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _PulsingDot(),
                ),
              ),

            // Attribution
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('© UrbanPulse Map',
                    style: TextStyle(fontSize: 9, color: Color(0xFF757575))),
              ),
            ),

            // Zoom controls
            const Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  _MapBtn(Icons.add_rounded),
                  SizedBox(height: 2),
                  _MapBtn(Icons.remove_rounded),
                ],
              ),
            ),

            // My location button
            const Positioned(
              right: 10,
              bottom: 28,
              child: _MapBtn(Icons.my_location_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.received:
        return const Color(0xFF9E9E9E);
      case ReportStatus.aiVerified:
        return const Color(0xFF1565C0);
      case ReportStatus.assignedToDept:
        return const Color(0xFFFB8C00);
      case ReportStatus.resolved:
        return const Color(0xFF43A047);
    }
  }

  IconData _catIcon(IssueCategory c) {
    switch (c) {
      case IssueCategory.pothole:
        return Icons.warning_amber_rounded;
      case IssueCategory.garbage:
        return Icons.delete_outline_rounded;
      case IssueCategory.brokenStreetlight:
        return Icons.lightbulb_outline_rounded;
      case IssueCategory.waterLeak:
        return Icons.water_drop_outlined;
      case IssueCategory.other:
        return Icons.help_outline_rounded;
    }
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _PinOverlay extends StatelessWidget {
  final double xRatio;
  final double yRatio;
  final Color color;
  final IconData icon;
  final double height;

  const _PinOverlay({
    required this.xRatio,
    required this.yRatio,
    required this.color,
    required this.icon,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      return Positioned(
        left: constraints.maxWidth * xRatio - 14,
        top: height * yRatio - 24,
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 13),
            ),
            CustomPaint(
              size: const Size(10, 7),
              painter: _TrianglePainter(color),
            ),
          ],
        ),
      );
    });
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas c, Size s) {
    c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(s.width, 0)
        ..lineTo(s.width / 2, s.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40 + 20 * _anim.value,
              height: 40 + 20 * _anim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE53935)
                    .withOpacity(0.15 * (1 - _anim.value)),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;

  const _MapBtn(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF424242)),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8F0E9),
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final block = Paint()..color = const Color(0xFFD6E3D6);
    final park = Paint()..color = const Color(0xFFC8DFC8);

    // Roads
    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.3), road);
    canvas.drawLine(Offset(0, size.height * 0.6),
        Offset(size.width, size.height * 0.6), road);
    canvas.drawLine(Offset(size.width * 0.35, 0),
        Offset(size.width * 0.35, size.height), road);
    canvas.drawLine(Offset(size.width * 0.68, 0),
        Offset(size.width * 0.68, size.height), road);
    canvas.drawLine(Offset(0, size.height * 0.45),
        Offset(size.width * 0.68, size.height * 0.45), minor);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3),
        Offset(size.width * 0.5, size.height), minor);

    // Blocks
    for (final r in [
      Rect.fromLTWH(10, 10, size.width * 0.28, size.height * 0.25),
      Rect.fromLTWH(size.width * 0.42, 10, size.width * 0.2, size.height * 0.25),
      Rect.fromLTWH(size.width * 0.72, 10, size.width * 0.26, size.height * 0.25),
      Rect.fromLTWH(10, size.height * 0.36, size.width * 0.28, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.42, size.height * 0.36, size.width * 0.2, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.72, size.height * 0.36, size.width * 0.26, size.height * 0.18),
      Rect.fromLTWH(10, size.height * 0.66, size.width * 0.28, size.height * 0.3),
      Rect.fromLTWH(size.width * 0.42, size.height * 0.66, size.width * 0.2, size.height * 0.3),
      Rect.fromLTWH(size.width * 0.72, size.height * 0.66, size.width * 0.26, size.height * 0.3),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), block);
    }

    // Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, size.width * 0.22, size.height * 0.18),
        const Radius.circular(4),
      ),
      park,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
