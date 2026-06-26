import 'package:flutter/material.dart';
import 'auth_theme.dart';
import '../../utils/snackbar_helper.dart';
// use named route for navigation to avoid circular imports
import 'sign_up_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full gradient background
      body: Container(
        decoration: const BoxDecoration(gradient: kThemeGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Slim AppBar row ─────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Center(
                    child: Column(
                      children: [
                        // Tagline
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue reporting\nurban issues in your city',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── White card ──────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF062B36),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Enter your credentials to access your account',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: authInputDecoration(
                                    'Email Address',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: kPrimaryTeal,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Please enter your email'
                                          : null,
                                ),
                                const SizedBox(height: 14),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscure,
                                  decoration: authInputDecoration(
                                    'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outlined,
                                      color: kPrimaryTeal,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey.shade500,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Please enter your password'
                                          : null,
                                ),
                                const SizedBox(height: 24),

                                // Login button — gradient
                                SizedBox(
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: _isLoading ? null : _handleSignIn,
                                    child: Container(
                                      height: 52,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: _isLoading
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF9EADB0),
                                                  Color(0xFF9EADB0),
                                                ],
                                              )
                                            : kThemeGradient,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: _isLoading
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: kPrimaryTeal
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 12,
                                                  offset:
                                                      const Offset(0, 5),
                                                ),
                                              ],
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // OR divider
                                Row(children: [
                                  Expanded(
                                      child: Divider(
                                          color: Colors.grey.shade200,
                                          thickness: 1.5)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: Colors.grey.shade200,
                                          thickness: 1.5)),
                                ]),

                                const SizedBox(height: 16),

                                // Google button
                                OutlinedButton(
                                  style: googleButtonStyle(),
                                  onPressed: _isLoading
                                      ? null
                                      : () => AuthService().signInWithGoogle(context),
                                  child: const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF3C4043),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Sign Up link ──────────────────────────────────
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen()),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final auth = FirebaseAuth.instance;
      final cred = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = cred.user;

      // Guard after first async gap
      if (!mounted) return;

      if (user == null) {
        SnackBarHelper.showError(context, 'Incorrect email or password');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // Check email verification
      if (!user.emailVerified) {
        SnackBarHelper.showInfo(context, 'Please verify your email before logging in.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // Check Firestore document exists
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Guard after second async gap
      if (!mounted) return;

      if (!doc.exists) {
        SnackBarHelper.showError(context, "Account doesn't exist, please sign up first.");
        await FirebaseAuth.instance.signOut();
        return;
      }

      // All good — navigate to main wrapper
      Navigator.pushNamedAndRemoveUntil(
          context, '/main', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        SnackBarHelper.showError(context, 'Incorrect email or password');
      } else {
        SnackBarHelper.showError(context, e.message ?? 'Sign in failed.');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
