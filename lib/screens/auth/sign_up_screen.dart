import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_theme.dart';
import '../../utils/snackbar_helper.dart';
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
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  String? _city;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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

  void _showCityPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return SizedBox(
          height: media.size.height * 0.7,
          child: Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: media.viewInsets.bottom + 12),
            child: Column(
              children: [
                Container(
                  height: 6,
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text('Search City',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final TextEditingController searchCtrl =
                      TextEditingController();
                  List<String> filtered = List.from(_cities);
                  return Expanded(
                    child: StatefulBuilder(builder: (context, setSheetState) {
                      return Column(
                        children: [
                          TextField(
                            controller: searchCtrl,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Type to search...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (q) {
                              final qq = q.trim().toLowerCase();
                              setSheetState(() {
                                filtered = _cities
                                    .where((c) =>
                                        c.toLowerCase().contains(qq))
                                    .toList();
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final city = filtered[i];
                                return ListTile(
                                  title: Text(city),
                                  onTap: () {
                                    setState(() => _city = city);
                                    Navigator.of(ctx).pop();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kThemeGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Slim AppBar row ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Account',
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Center(
                    child: Column(
                      children: [
                        if (!_verificationPending) ...[
                          const Text(
                            'Join thousands of citizens making\ntheir city a better place',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── White card ─────────────────────────────────────
                          GlassAuthCard(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header
                                  const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Fill in your details to create your account',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  TextFormField(
                                    controller: _name,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: authInputDecoration(
                                      'Full Name',
                                      prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    readOnly: true,
                                    onTap: _showCityPicker,
                                    controller: TextEditingController(
                                        text: _city ?? ''),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: authInputDecoration(
                                      'City',
                                      prefixIcon: const Icon(
                                        Icons.location_city_outlined,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      suffixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (_) =>
                                        (_city == null || _city!.isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: _email,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: authInputDecoration(
                                      'Email Address',
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: _phone,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: authInputDecoration(
                                      'Phone Number (03XXXXXXXXX)',
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    validator: (value) {
                                      final cleanVal = value?.trim() ?? '';
                                      if (cleanVal.isEmpty) return 'Required';
                                      if (cleanVal.length != 11)
                                        return 'Must be 11 digits';
                                      if (!cleanVal.startsWith('03'))
                                        return 'Must start with 03';
                                      if (!RegExp(r'^[0-9]+$')
                                          .hasMatch(cleanVal))
                                        return 'Only digits allowed';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: _password,
                                    style: const TextStyle(color: Colors.white),
                                    obscureText: _obscurePassword,
                                    decoration: authInputDecoration(
                                      'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outlined,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Required';
                                      if (v.length < 8)
                                        return 'Must be at least 8 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: _confirm,
                                    style: const TextStyle(color: Colors.white),
                                    obscureText: _obscureConfirm,
                                    decoration: authInputDecoration(
                                      'Confirm Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                            () => _obscureConfirm =
                                                !_obscureConfirm),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Required';
                                      if (v != _password.text)
                                        return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),

                                  // Sign Up button â€” gradient
                                  GestureDetector(
                                    onTap: _isLoading ? null : _handleSignUp,
                                    child: Container(
                                      height: 52,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        gradient: _isLoading
                                            ? const LinearGradient(colors: [
                                                Color(0xFF9EADB0),
                                                Color(0xFF9EADB0),
                                              ])
                                            : kThemeGradient,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: _isLoading
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: kPrimaryTeal
                                                      .withOpacity(0.4),
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
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

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

                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignInScreen()),
                                ),
                                child: const Text(
                                  'Sign In',
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
                        ] else ...[
                          // ── Verification Pending Card ───────────────────
                          const SizedBox(height: 20),
                          GlassAuthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email icon
                                Container(
                                  width: 70,
                                  height: 70,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.mark_email_unread_outlined,
                                      color: Colors.white, size: 34),
                                ),
                                const Text(
                                  'Verify Your Email',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'A verification link has been sent to your email. Please verify it to continue.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: _isLoading ? null : _checkVerification,
                                  child: Container(
                                    height: 52,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: kThemeGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: kPrimaryTeal.withOpacity(0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white),
                                          )
                                        : const Text(
                                            'I have verified my email',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  style: outlinedGreenStyle(),
                                  onPressed: (_resendSeconds > 0 || _isLoading)
                                      ? null
                                      : _resendEmail,
                                  child: Text(
                                    _resendSeconds > 0
                                        ? 'Resend Email ($_resendSeconds s)'
                                        : 'Resend Email',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _isLoading ? null : _cancelVerification,
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Color(0xFFE53935),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final auth = AuthService();
      final cred = await auth.registerWithEmailAndPassword(
          _email.text.trim(), _password.text.trim());
      final uid = cred.user?.uid;
      if (uid != null) {
        final cleanPhone = _phone.text.trim();
        try {
          await auth.sendEmailVerification(cred.user!);
        } catch (e) {
          print('Failed to send verification email: $e');
        }

        _pendingUid = uid;
        _pendingProfile = {
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'phoneNumber': cleanPhone,
          'city': _city ?? '',
          'profileImageUrl': '',
        };

        setState(() {
          _verificationPending = true;
          _startResendCooldown();
        });
      }
    } on FirebaseException catch (e) {
      print('FirebaseException during registration: $e');
      SnackBarHelper.showError(context, e.message ?? 'Email already in use.');
    } catch (e) {
      print('Registration error: $e');
      SnackBarHelper.showError(context, 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        if (_pendingUid != null && _pendingProfile != null) {
          final auth = AuthService();
          await auth.createUserProfile(_pendingUid!, _pendingProfile!);
        }
        SnackBarHelper.showSuccess(context, 'Email verified â€” welcome!');
        Navigator.pushNamedAndRemoveUntil(
            context, '/main', (route) => false);
      } else {
        SnackBarHelper.showInfo(context, 'Email not verified yet. Please check your inbox.');
      }
    } catch (e) {
      print('Verification check error: $e');
      SnackBarHelper.showError(context, 'Verification check failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final auth = AuthService();
        await auth.sendEmailVerification(user);
        SnackBarHelper.showSuccess(context, 'Verification email resent successfully.');
        _startResendCooldown();
      }
    } catch (e) {
      print('Resend email failed: $e');
      SnackBarHelper.showError(context, 'Failed to resend verification email.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelVerification() async {
    await AuthService().signOut();
    setState(() {
      _verificationPending = false;
      _pendingUid = null;
      _pendingProfile = null;
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const SignInScreen()));
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
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _phone.dispose();
    super.dispose();
  }
}