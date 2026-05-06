import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_theme.dart';
import 'email_verification_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _first = TextEditingController();
  final TextEditingController _last = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String? _city;
  bool _isLoading = false;
  bool _verificationPending = false;
  String? _pendingUid;
  Map<String, dynamic>? _pendingProfile;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  static const List<String> _cities = [
    "Bahawalpur",
    "Bhakkar",
    "Dera Ghazi Khan",
    "Faisalabad",
    "Gujranwala",
    "Jhang",
    "Kasur",
    "Lahore",
    "Mianwali",
    "Multan",
    "Okara",
    "Rahim Yar Khan",
    "Rawalpindi",
    "Sahiwal",
    "Sargodha",
    "Sheikhupura",
    "Sialkot",
    "Taxila",
    "Wah Cantt",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Create Account', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_verificationPending) ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: TextFormField(controller: _first, decoration: authInputDecoration('First Name'), validator: (v) => (v==null||v.isEmpty)?'Required':null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _last, decoration: authInputDecoration('Last Name'), validator: (v) => (v==null||v.isEmpty)?'Required':null)),
                    ]),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: authInputDecoration('City'),
                      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      value: _city,
                      onChanged: (v) => setState(() => _city = v),
                      validator: (v) => (v==null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _email, decoration: authInputDecoration('Email'), keyboardType: TextInputType.emailAddress, validator: (v) => (v==null||v.isEmpty)?'Required':null),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      decoration: authInputDecoration('Phone'),
                      keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          final cleanVal = value?.trim() ?? '';
                          if (cleanVal.isEmpty) return 'Required';
                          if (cleanVal.length != 11) return 'Must be 11 digits';
                          if (!cleanVal.startsWith('03')) return 'Must start with 03';
                          if (!RegExp(r'^[0-9]+$').hasMatch(cleanVal)) return 'Only digits allowed';
                          return null;
                        },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _password, decoration: authInputDecoration('Password'), obscureText: true, validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    }),
                    const SizedBox(height: 12),
                    TextFormField(controller: _confirm, decoration: authInputDecoration('Confirm Password'), obscureText: true, validator: (v) {
                      if (v==null||v.isEmpty) return 'Required';
                      if (v != _password.text) return 'Passwords do not match';
                      return null;
                    }),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: primaryButtonStyle(),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (!(_formKey.currentState?.validate() ?? false)) return;
                              setState(() => _isLoading = true);
                              try {
                                final auth = AuthService();
                                // register
                                final cred = await auth.registerWithEmailAndPassword(_email.text.trim(), _password.text.trim());
                                final uid = cred.user?.uid;
                                if (uid != null) {
                                  final cleanPhone = _phone.text.trim();
                                  // send email verification
                                  try {
                                    await auth.sendEmailVerification(cred.user!);
                                  } catch (e) {
                                    print('Failed to send verification email: $e');
                                  }

                                  // store pending profile to write after verification
                                  _pendingUid = uid;
                                  _pendingProfile = {
                                    'firstName': _first.text.trim(),
                                    'lastName': _last.text.trim(),
                                    'city': _city ?? '',
                                    'phoneNumber': cleanPhone,
                                    'reputationScore': 0,
                                    'email': _email.text.trim(),
                                  };

                                  // enter verification pending state
                                  setState(() {
                                    _verificationPending = true;
                                    _startResendCooldown();
                                  });
                                }
                              } on FirebaseException catch (e) {
                                print('FirebaseException during registration: $e');
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Registration failed')));
                              } catch (e) {
                                print('Registration error: $e');
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                      child: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign Up'),
                    ),
                    const SizedBox(height: 12),
                    const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal:8.0), child: Text('OR')), Expanded(child: Divider())]),
                    const SizedBox(height: 12),
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/google_login.svg',
                        height: 46,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Verification pending UI
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text('A verification link has been sent to your email. Please verify it to continue.', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: primaryButtonStyle(),
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        // reload current user
                        await FirebaseAuth.instance.currentUser?.reload();
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.emailVerified) {
                          // write Firestore doc now
                          if (_pendingUid != null && _pendingProfile != null) {
                            final auth = AuthService();
                            await auth.createUserProfile(_pendingUid!, _pendingProfile!);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email verified — welcome!')));
                          // navigate to main app
                          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email not verified yet. Please check your inbox.')));
                        }
                      } catch (e) {
                        print('Verification check error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification check failed')));
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: _isLoading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Text('I have verified my email'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: primaryButtonStyle(),
                    onPressed: (_resendSeconds > 0 || _isLoading) ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final auth = AuthService();
                          await auth.sendEmailVerification(user);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email resent')));
                          _startResendCooldown();
                        }
                      } catch (e) {
                        print('Resend email failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resend email')));
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: Text(_resendSeconds > 0 ? 'Resend Email ($_resendSeconds)' : 'Resend Email'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : () async {
                      // cancel: sign out and return to sign-in
                      await AuthService().signOut();
                      setState(() {
                        _verificationPending = false;
                        _pendingUid = null;
                        _pendingProfile = null;
                      });
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    super.dispose();
  }
}
