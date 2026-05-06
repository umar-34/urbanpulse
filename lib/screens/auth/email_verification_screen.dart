import 'package:flutter/material.dart';
import 'auth_theme.dart';
import 'profile_completion_screen.dart';

class EmailVerificationMockScreen extends StatelessWidget {
  const EmailVerificationMockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Email Verification', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.mark_email_unread, size: 96, color: kPrimaryBlue),
            const SizedBox(height: 24),
            const Text(
              "Verify your email. We've sent a link to your inbox.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            ElevatedButton(
              style: primaryButtonStyle(),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileCompletionScreen())),
              child: const Text('[Dev Mode] Simulate Verification Clicks'),
            ),
          ],
        ),
      ),
    );
  }
}
