import 'package:flutter/material.dart';
import 'auth_theme.dart';
// use named route for navigation to avoid circular imports
import 'sign_up_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Welcome Back', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: authInputDecoration('Email'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: authInputDecoration('Password', prefix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: primaryButtonStyle(),
                    onPressed: _isLoading ? null : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      setState(() => _isLoading = true);
                      try {
                        final auth = FirebaseAuth.instance;
                        final cred = await auth.signInWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                        );

                        final user = cred.user;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email or password.')));
                          await FirebaseAuth.instance.signOut();
                          return;
                        }

                        // Check email verification
                        if (!user.emailVerified) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify your email before logging in')));
                          await FirebaseAuth.instance.signOut();
                          return;
                        }

                        // Check Firestore document exists
                        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                        if (!doc.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account profile not found. Please Sign Up first.')));
                          await FirebaseAuth.instance.signOut();
                          return;
                        }

                        // All good — navigate to main wrapper
                        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email or password.')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign in failed')));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in failed')));
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Login'),
                  ),
                  const SizedBox(height: 12),
                  const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal:8.0), child: Text('OR')), Expanded(child: Divider())]),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/google_login.svg',
                        height: 46,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                  child: const Text('Sign Up', style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
