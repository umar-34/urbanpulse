import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6),
    ));
    _scale =
        Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    ));

    _ctrl.forward();

    // Load data then navigate after at least 2.5 seconds
    Future.wait([
      context.read<ReportProvider>().load(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]).then((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Spacer(flex: 2),
                ScaleTransition(
                  scale: _scale,
                  child: Center(
                    child: Column(
                      children: [
                        // Logo mark
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.07),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF1565C0),
                                      width: 2.5),
                                ),
                              ),
                              const Icon(Icons.location_city_rounded,
                                  color: Color(0xFF1565C0), size: 38),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF43A047),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on,
                                      color: Colors.white, size: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                              text: 'Urban',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1565C0),
                                  letterSpacing: -0.5),
                            ),
                            TextSpan(
                              text: 'Pulse',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF43A047),
                                  letterSpacing: -0.5),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Intelligent Urban Reporting System',
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                              letterSpacing: 0.2),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                Column(
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: const Color(0xFF1565C0).withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connecting Citizens & Cities',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBDBDBD),
                          letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
