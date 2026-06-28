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
      SnackBarHelper.showSuccess(context, 'Welcome to UrbanPulse! ðŸŽ‰');
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
                  'One Last Step! ðŸ‘‹',
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
                GlassAuthCard(
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
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Required for municipality follow-ups',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _phone,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            decoration: authInputDecoration(
                              'Phone Number',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter your phone number'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            readOnly: true,
                            onTap: _showCityPicker,
                            controller:
                                TextEditingController(text: _city ?? ''),
                            style: const TextStyle(color: Colors.white),
                            decoration: authInputDecoration(
                              'Select Your City',
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
                            validator: (_) => (_city == null || _city!.isEmpty)
                                ? 'Please select your city'
                                : null,
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

                const SizedBox(height: 24),
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
