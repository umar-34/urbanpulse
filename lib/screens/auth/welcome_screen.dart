import 'package:flutter/material.dart';
import 'auth_theme.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', height: 120),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(text: 'Urban', style: TextStyle(color: kPrimaryBlue)),
                          TextSpan(text: 'Pulse', style: TextStyle(color: kPrimaryGreen)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Intelligent Urban Reporting System',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: primaryButtonStyle(),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: outlinedGreenStyle(),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
