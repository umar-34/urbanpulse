import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6),
    ));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    ));

    _ctrl.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final futures = <Future>[
      context.read<ReportProvider>().load(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ];

    final user = FirebaseAuth.instance.currentUser;
    bool needsProfileCompletion = false;

    if (user != null) {
      futures.add(
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .then((doc) async {
          final data = doc.data();
          final phone = data?['phoneNumber'] as String?;
          final city = data?['city'] as String?;

          if (phone == null || phone.isEmpty || city == null || city.isEmpty) {
            await FirebaseAuth.instance.signOut();
            try {
              await GoogleSignIn().signOut();
            } catch (_) {}
            needsProfileCompletion = true;
          }
        }).catchError((_) {}),
      );
    }

    await Future.wait(futures);

    if (mounted) {
      if (user == null || needsProfileCompletion) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
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
                          Image.asset(
                            'assets/images/urbanPulse.png',
                            height: 160,
                            fit: BoxFit.contain,
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
                          color: const Color(0xFF064554).withOpacity(0.55),
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
