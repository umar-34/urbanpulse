import 'package:flutter/material.dart';
import 'auth_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// navigate using named routes to avoid circular imports

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('One Last Step!', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text('Please provide your contact details for municipality follow-ups.', style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: authInputDecoration('Phone Number'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: authInputDecoration('City'),
                    items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    initialValue: _city,
                    onChanged: (v) => setState(() => _city = v),
                    validator: (v) => (v == null || v.isEmpty) ? 'Select city' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: primaryButtonStyle(),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) return;
                            setState(() => _isLoading = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                throw Exception('No authenticated user');
                              }
                              final uid = user.uid;
                              await FirebaseFirestore.instance.collection('users').doc(uid).set({
                                'city': _city,
                                'phoneNumber': _phone.text.trim(),
                                'reputationScore': 0,
                              }, SetOptions(merge: true));

                              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                            } on FirebaseException catch (e) {
                              print('FirebaseException while completing profile: $e');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Failed to save profile')));
                            } catch (e) {
                              print('Error while completing profile: $e');
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Complete Profile & Enter App'),
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
