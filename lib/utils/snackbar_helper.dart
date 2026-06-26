import 'package:flutter/material.dart';

/// Centralised helper for displaying modern, floating SnackBars
/// throughout the UrbanPulse application.
class SnackBarHelper {
  SnackBarHelper._(); // prevent instantiation

  static const Color _successBg = Color(0xFF1B6B47);
  static const Color _errorBg   = Color(0xFFC0392B);
  static const Color _infoBg    = Color(0xFF064554);
  static const Duration _kDuration = Duration(seconds: 3);

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: _successBg, icon: Icons.check_circle_outline_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: _errorBg, icon: Icons.error_outline_rounded);
  }

  static void showInfo(BuildContext context, String message, {bool isNetwork = false}) {
    _show(context, message: message, backgroundColor: _infoBg, icon: isNetwork ? Icons.wifi_off_rounded : Icons.info_outline_rounded);
  }

  static void _show(BuildContext context, {required String message, required Color backgroundColor, required IconData icon}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _kDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'x',
            textColor: Colors.white70,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
  }
}
