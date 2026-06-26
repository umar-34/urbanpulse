import 'package:flutter/material.dart';
import 'auth_theme.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryTeal, kPrimaryTealLight, Color(0xFF0d8a9e)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Decorative blobs ──────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    // Background decorative circles (glassmorphism blobs)
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 80,
                      left: -60,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kPrimaryTealLight.withOpacity(0.3),
                        ),
                      ),
                    ),
                    // ── Hero content ─────────────────────────────────────────
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glowing logo container
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.18),
                                  blurRadius: 32,
                                  spreadRadius: 6,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2),
                                  ),
                                ),
                                const Icon(Icons.location_city_rounded,
                                    color: Colors.white, size: 44),
                                Positioned(
                                  bottom: 14,
                                  right: 14,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00BFA5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.location_on,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.w800),
                              children: [
                                TextSpan(
                                    text: 'Urban',
                                    style: TextStyle(color: Colors.white)),
                                TextSpan(
                                    text: 'Pulse',
                                    style: TextStyle(color: Color(0xFF80DEEA))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Intelligent Urban Reporting System',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: const Text(
                              'Report · Track · Resolve',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── CTA card ─────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 36,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF062B36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Join thousands of citizens making their city better',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 24),
                    // Sign In button — gradient
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignInScreen())),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: kThemeGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryTeal.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Create Account button — outlined teal
                    OutlinedButton(
                      style: outlinedGreenStyle(),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: const Text('Create Account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
