import 'package:flutter/material.dart';

const Color kPrimaryBlue = Color(0xFF1565C0);
const Color kPrimaryGreen = Color(0xFF4CAF50);

InputDecoration authInputDecoration(String label, {Widget? prefix}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: prefix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
    ),
  );
}

ButtonStyle primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: kPrimaryBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

ButtonStyle outlinedGreenStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: kPrimaryGreen,
    side: const BorderSide(color: kPrimaryGreen),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}
