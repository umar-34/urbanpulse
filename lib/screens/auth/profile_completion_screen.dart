import 'package:flutter/material.dart';
import 'auth_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/snackbar_helper.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phone = TextEditingController();
  String? _city;
  bool _isLoading = false;

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
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'city': _city,
          'phoneNumber': _phone.text.trim(),
          'reputationScore': 0,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Welcome to UrbanPulse! 🎉');
      Navigator.pushNamedAndRemoveUntil(
          context, '/main', (route) => false);
    } on FirebaseException catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, e.message ?? 'Failed to save profile.');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to save profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // ── Light teal gradient background ─────────────────────────────────
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064554), Color(0xFF0a6378)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                const SizedBox(height: 16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_pin_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'One Last Step! 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help us personalise your experience\nand connect you with your city.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Elevated Card ───────────────────────────────────────────
                Card(
                  elevation: 16,
                  shadowColor: Colors.black38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF062B36),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Required for municipality follow-ups',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Phone Number ──────────────────────────────────
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: authInputDecoration(
                              'Phone Number',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: kPrimaryTeal,
                                size: 20,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your phone number'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── City Dropdown ─────────────────────────────────
                          DropdownButtonFormField<String>(
                            decoration: authInputDecoration(
                              'Select Your City',
                              prefixIcon: const Icon(
                                Icons.location_city_outlined,
                                color: kPrimaryTeal,
                                size: 20,
                              ),
                            ),
                            initialValue: _city,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: kPrimaryTeal),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            items: _cities
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF062B36)),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _city = v),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Please select your city' : null,
                          ),

                          const SizedBox(height: 32),

                          // ── Complete Profile Button ────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _completeProfile,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 54,
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
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isLoading
                                      ? []
                                      : [
                                          BoxShadow(
                                            color:
                                                kPrimaryTeal.withValues(alpha: 0.4),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
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
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle_outline_rounded,
                                              color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Complete Profile',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
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
                ),

                const SizedBox(height: 24),
                // ── Footer note ─────────────────────────────────────────────
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        color: Colors.white54, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Your data is secure & never shared',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
