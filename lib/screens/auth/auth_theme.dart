import 'package:flutter/material.dart';

// ─── Brand Colors ────────────────────────────────────────────────────────────
const Color kPrimaryTeal = Color(0xFF064554);      // Primary deep teal
const Color kPrimaryTealLight = Color(0xFF0a6378); // Gradient end / lighter teal
const Color kAccentCyan = Color(0xFF00BFA5);        // Accent for highlights

// Kept for backward compatibility — now maps to teal
const Color kPrimaryBlue = kPrimaryTeal;

// ─── Global Theme Gradient ───────────────────────────────────────────────────
const LinearGradient kThemeGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kPrimaryTeal, kPrimaryTealLight],
);

// ─── Input Decoration ────────────────────────────────────────────────────────
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
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryTeal, width: 2),
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
    backgroundColor: kPrimaryTeal,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
    shadowColor: kPrimaryTeal.withOpacity(0.4),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );
}

ButtonStyle outlinedGreenStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: kPrimaryTeal,
    side: const BorderSide(color: kPrimaryTeal, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

ButtonStyle googleButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF3C4043),
    backgroundColor: Colors.white,
    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    elevation: 0,
  );
}
