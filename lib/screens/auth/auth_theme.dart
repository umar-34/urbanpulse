import 'dart:ui';
import 'package:flutter/material.dart';

const Color kPrimaryTeal = Color(0xFF064554); // Primary deep teal
const Color kPrimaryTealLight =
    Color(0xFF0a6378); // Gradient end / lighter teal
const Color kAccentCyan = Color(0xFF00BFA5); // Accent for highlights

const Color kPrimaryBlue = kPrimaryTeal;

const LinearGradient kThemeGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kPrimaryTeal, kPrimaryTealLight],
);

InputDecoration authInputDecoration(
  String label, {
  Widget? prefix,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefixIcon ?? prefix,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withOpacity(0.15), // Transparent glass for input
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
    ),
  );
}

// ─── Button Styles ───────────────────────────────────────────────────────────
ButtonStyle primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: kAccentCyan,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
    shadowColor: kAccentCyan.withOpacity(0.4),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );
}

ButtonStyle outlinedGreenStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

ButtonStyle googleButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF3C4043),
    backgroundColor: Colors.white.withOpacity(0.9), // Keep white for visibility
    side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    elevation: 0,
  );
}

class GlassAuthCard extends StatelessWidget {
  final Widget child;

  const GlassAuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
