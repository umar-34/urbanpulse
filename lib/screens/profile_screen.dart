import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications_screen.dart';
import '../providers/report_provider.dart';
import 'create_report_screen.dart';
import '../services/location_service.dart';
import '../utils/snackbar_helper.dart';
import '../services/media_service.dart';

const String privacyPolicyText =
    'UrbanPulse collects your name, email, phone number, location data, and submitted report images solely to authenticate your account and accurately map urban issues for civic resolution. All profile data and media are stored securely using Firebase Authentication, Firestore, and Cloud Storage, ensuring passwords are securely encrypted via one-way cryptographic hashing. This application is developed strictly as an academic Final Year Project at UET Taxila for evaluation purposes. By using the app, you consent to the secure collection and processing of this data within our cloud infrastructure. You can update your profile information at any time through the application settings.';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String? _profileImagePath;
  final TextEditingController _nameCtrl = TextEditingController();

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  double? _latitude;
  double? _longitude;
  String? _locationError;
  String _profileLocationLabel = '';
  final Set<String> _invalidFields = <String>{};

  Future<void> _editProfile() async {
    // fetch latest user doc and seed controllers
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        _nameCtrl.text = (data?['name'] as String?) ?? '';
        _phoneCtrl.text = (data?['phoneNumber'] as String?) ?? '';
        _emailCtrl.text = (data?['email'] as String?) ??
            FirebaseAuth.instance.currentUser?.email ??
            '';
      } catch (_) {
        // ignore and fall back to existing values
        _nameCtrl.text = _name;
        _emailCtrl.text = _email;
      }
    } else {
      _nameCtrl.text = _name;
      _emailCtrl.text = _email;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetCtx) {
        bool localSaving = false;
        return StatefulBuilder(builder: (cctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Text('Edit Profile',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 6),
                    const Text('Update your personal details below.',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF78909C))),
                    const SizedBox(height: 24),
                    _sheetField(
                        _nameCtrl, 'Full Name', Icons.person_outline_rounded),
                    const SizedBox(height: 16),
                    _sheetField(
                        _phoneCtrl, 'Mobile Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    // Email is read-only
                    TextField(
                      controller: _emailCtrl,
                      enabled: false,
                      style: const TextStyle(color: Color(0xFF78909C)),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color(0xFF78909C), size: 22),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (localSaving || _nameCtrl.text.trim().isEmpty)
                                ? null
                                : () async {
                                    setModalState(() => localSaving = true);
                                    await updateUserProfile();
                                    setModalState(() => localSaving = false);
                                    Navigator.pop(sheetCtx);
                                  },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064554),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: localSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
            ),
          );
        });
      },
    );
  }

  Widget _contributionBarWithRate(double pct, int percentage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resolution Rate',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF78909C),
                      fontWeight: FontWeight.w600)),
              Text('$percentage%',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF43A047),
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFE0E0E0),
              color: const Color(0xFF43A047),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfileImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (_profileImagePath != null)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Color(0xFFE53935))),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, ''),
            ),
          ],
        ),
      ),
    );

    if (choice == null || choice.isEmpty) return;
    try {
      if (choice == 'remove') {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'profileImageUrl': null}, SetOptions(merge: true));
        }
        setState(() => _profileImagePath = null);
        return;
      }
      final src = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final res = await MediaService.pickImage(source: src);
      if (res != null) {
        // Save local path into user document so both screens update
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'profileImageUrl': res.path}, SetOptions(merge: true));
        }
        setState(() => _profileImagePath = res.path);
      }
    } catch (_) {}
  }

  Widget _sheetField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF064554), size: 22),
        filled: true,
        fillColor: const Color(0xFFF0F4FF).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF064554), width: 1.5),
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF064554).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_city_rounded,
                  color: Color(0xFF064554), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('UrbanPulse',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Version 1.0.0\n\n'
          'UrbanPulse is an Intelligent Urban Reporting System that empowers '
          'citizens to report urban issues like potholes, garbage, broken '
          'streetlights, and water leaks directly to city authorities.\n\n'
          'Built with Flutter • AI-Powered Verification',
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF424242)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: Color(0xFF064554))),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF064554).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.privacy_tip_outlined,
                  color: Color(0xFF064554), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Privacy Policy',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          privacyPolicyText,
          textAlign: TextAlign.justify,
          style: const TextStyle(
              fontSize: 13, height: 1.6, color: Color(0xFF424242)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: Color(0xFF064554))),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close the dialog first
              try {
                // 1. Clear Firestore offline persistence / cache
                try {
                  // This can throw 'failed-precondition' if there are active snapshot listeners.
                  await FirebaseFirestore.instance.terminate();
                  await FirebaseFirestore.instance.clearPersistence();
                } catch (e) {
                  debugPrint('Firestore clear persistence error: $e');
                }

                // 2. Clear Google Sign-In session to force account picker next time
                try {
                  final googleSignIn = GoogleSignIn();
                  if (await googleSignIn.isSignedIn()) {
                    await googleSignIn.disconnect();
                    await googleSignIn.signOut();
                  }
                } catch (e) {
                  debugPrint('Google Sign-In disconnect error: $e');
                }

                // 3. Clear any local SharedPreferences login flags
                try {
                  final prefs = await SharedPreferences.getInstance();
                  if (prefs.containsKey('isLoggedIn')) {
                    await prefs.remove('isLoggedIn');
                  }
                } catch (e) {
                  debugPrint('SharedPreferences error: $e');
                }

                // 4. Sign out of Firebase Authentication
                await FirebaseAuth.instance.signOut();

                // 5. Navigate to Welcome Screen and clear the entire navigation stack
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/welcome', (Route<dynamic> route) => false);
                }
              } catch (e) {
                debugPrint('Logout error: $e');
                if (mounted) {
                  SnackBarHelper.showError(
                      context, 'Failed to log out properly. Please try again.');
                }
              }
            },
            child: const Text('Log Out',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _address1Ctrl.dispose();
    _streetCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _landmarkCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _loadUserProfileFromFirestore();
  }

  Future<void> _loadUserProfileFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return;
      final data = doc.data();
      final name =
          (data?['name'] as String?) ?? (data?['fullName'] as String?) ?? '';
      final phone = (data?['phoneNumber'] as String?) ?? '';
      final email = (data?['email'] as String?) ??
          FirebaseAuth.instance.currentUser?.email ??
          '';
      final img = (data?['profileImageUrl'] as String?) ?? _profileImagePath;
      setState(() {
        _name = name;
        _email = email;
        _profileImagePath = img;
        _nameCtrl.text = _name;
        _phoneCtrl.text = phone;
        _emailCtrl.text = _email;
      });
    } catch (_) {}
  }

  Future<void> updateUserProfile() async {
    final nameVal = _nameCtrl.text.trim();
    final phoneVal = _phoneCtrl.text.trim();
    if (nameVal.isEmpty) {
      SnackBarHelper.showError(context, 'Name cannot be empty.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameVal,
        'phoneNumber': phoneVal,
      }, SetOptions(merge: true));
      setState(() {
        _name = nameVal;
      });
      SnackBarHelper.showSuccess(context, 'Profile updated successfully.');
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to update profile: $e');
    }
  }

  Future<void> _loadSavedLocation() async {
    // Load basic cached prefs if present, but prefer Firestore as source-of-truth.
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('profile_city') ?? '';
    final area = prefs.getString('profile_area') ?? '';
    final lat = prefs.getDouble('profile_lat');
    final lon = prefs.getDouble('profile_lon');
    final img = prefs.getString('profile_image');
    setState(() {
      if (area.isNotEmpty) _areaCtrl.text = area;
      if (city.isNotEmpty) _cityCtrl.text = city;
      if (lat != null) _latitude = lat;
      if (lon != null) _longitude = lon;
      _profileImagePath = img;
      _profileLocationLabel = city.isNotEmpty ? city : '';
    });
  }

  void _showLocationSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: media.viewInsets.bottom + 20),
          child: StatefulBuilder(builder: (context, setState) {
            bool _isSaving = false;
            String? _selectedCity;
            final outerSetState = setState;

            return Container(
              height: media.size.height * 0.45,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    height: 6,
                    width: 60,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text('Update Location',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final selected = await Navigator.of(ctx).push<String>(
                        MaterialPageRoute(builder: (cctx) {
                          final TextEditingController searchCtrl =
                              TextEditingController();
                          final media = MediaQuery.of(cctx);
                          return Scaffold(
                            appBar: AppBar(
                              title: const Text('Search City'),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A1A2E),
                              elevation: 1,
                            ),
                            body: Padding(
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
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: StatefulBuilder(
                                        builder: (context2, innerSetState) {
                                      // initialize filtered on first build and allow searching
                                      List<String> currentFiltered = List.from(
                                          PUNJAB_CITIES.where((c) => c
                                              .toLowerCase()
                                              .contains(searchCtrl.text
                                                  .trim()
                                                  .toLowerCase())));
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
                                              innerSetState(() {});
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: ListView.separated(
                                              itemCount: currentFiltered.length,
                                              separatorBuilder: (_, __) =>
                                                  const Divider(height: 1),
                                              itemBuilder: (context, i) {
                                                final city = currentFiltered[i];
                                                final isSelected =
                                                    city == _selectedCity;
                                                return ListTile(
                                                  title: Text(
                                                    city,
                                                    style: TextStyle(
                                                        color: isSelected
                                                            ? Theme.of(context)
                                                                .primaryColor
                                                            : null,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : null),
                                                  ),
                                                  trailing: isSelected
                                                      ? Icon(Icons.check,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor)
                                                      : null,
                                                  onTap: () {
                                                    Navigator.pop(cctx, city);
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          // react to text changes
                                          Builder(builder: (_) {
                                            searchCtrl.addListener(() {
                                              innerSetState(() {});
                                            });
                                            return const SizedBox.shrink();
                                          }),
                                        ],
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );

                      if (selected != null) {
                        outerSetState(() {
                          _selectedCity = selected;
                          _cityCtrl.text = selected;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _cityCtrl,
                        onChanged: (v) {
                          if (v.trim().isNotEmpty &&
                              _invalidFields.remove('city')) {
                            setState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'City *',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          errorText: _invalidFields.contains('city')
                              ? 'Required'
                              : null,
                          suffixIcon:
                              const Icon(Icons.keyboard_arrow_down_rounded),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _invalidFields.contains('city')
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _invalidFields.contains('city')
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFF064554),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Auto-location removed per UI requirement.
                  if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_locationError!,
                          style: const TextStyle(color: Color(0xFFE53935))),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  final streetVal = _streetCtrl.text.trim();
                                  final cityVal = _cityCtrl.text.trim();
                                  _invalidFields.remove('street');
                                  _invalidFields.remove('city');
                                  if (streetVal.isEmpty || cityVal.isEmpty) {
                                    if (streetVal.isEmpty)
                                      _invalidFields.add('street');
                                    if (cityVal.isEmpty)
                                      _invalidFields.add('city');
                                    setState(() {});
                                    return;
                                  }
                                  setState(() {
                                    _isSaving = true;
                                  });
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final existingStreet =
                                        prefs.getString('profile_street') ?? '';
                                    final existingCity =
                                        prefs.getString('profile_city') ?? '';
                                    final wouldOverwrite =
                                        (existingStreet.isNotEmpty &&
                                                existingStreet != streetVal) ||
                                            (existingCity.isNotEmpty &&
                                                existingCity != cityVal);
                                    if (wouldOverwrite) {
                                      final confirm = await showDialog<bool>(
                                        context: ctx,
                                        builder: (_) => AlertDialog(
                                          title:
                                              const Text('Confirm overwrite'),
                                          content: const Text(
                                              'You already have a saved Street/City. Do you want to overwrite it?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(_, false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(_, true),
                                                child: const Text('Overwrite')),
                                          ],
                                        ),
                                      );
                                      if (confirm != true) {
                                        if (mounted)
                                          setState(() => _isSaving = false);
                                        return;
                                      }
                                    }

                                    final selected = _selectedCity ?? cityVal;
                                    await prefs.setString(
                                        'profile_city', selected);
                                    await prefs.setString(
                                        'profile_area', _areaCtrl.text.trim());
                                    await prefs.setString(
                                        'profile_street', streetVal);
                                    if (_latitude != null)
                                      await prefs.setDouble(
                                          'profile_lat', _latitude!);
                                    if (_longitude != null)
                                      await prefs.setDouble(
                                          'profile_lon', _longitude!);

                                    final uid =
                                        FirebaseAuth.instance.currentUser?.uid;
                                    if (uid != null) {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .set({
                                        'city': selected,
                                        'location': selected,
                                        'area': _areaCtrl.text.trim(),
                                        'street': streetVal,
                                        if (_latitude != null) 'lat': _latitude,
                                        if (_longitude != null)
                                          'lon': _longitude,
                                      }, SetOptions(merge: true));
                                    }

                                    // Update local label and stop spinner before closing
                                    setState(() {
                                      if (streetVal.isNotEmpty &&
                                          cityVal.isNotEmpty) {
                                        _profileLocationLabel =
                                            '$streetVal, $cityVal';
                                      } else if (_areaCtrl.text
                                              .trim()
                                              .isNotEmpty &&
                                          cityVal.isNotEmpty) {
                                        _profileLocationLabel =
                                            '${_areaCtrl.text.trim()}, $cityVal';
                                      } else if (cityVal.isNotEmpty) {
                                        _profileLocationLabel = cityVal;
                                      } else {
                                        _profileLocationLabel = '';
                                      }
                                      _isSaving = false;
                                    });

                                    // Auto-close the bottom sheet and show success feedback
                                    if (mounted) {
                                      Navigator.pop(context);
                                      SnackBarHelper.showSuccess(context, 'Location updated successfully.');
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                      SnackBarHelper.showError(context, 'Failed to update location: $e');
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Save Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        // Compute points: 5 per report, +10 bonus per resolved
        final points = provider.totalCount * 5 + provider.resolvedCount * 10;

        return Scaffold(
          backgroundColor: const Color(0xFFF0F4FF),
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF064554), Color(0xFF0a6378)],
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          body: ListView(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _changeProfileImage,
                          child: StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseAuth.instance.currentUser == null
                                ? const Stream.empty()
                                : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .snapshots(),
                            builder: (context, snap) {
                              String? imgPath;
                              if (snap.hasData &&
                                  snap.data != null &&
                                  snap.data!.exists) {
                                imgPath = (snap.data!.data()?['profileImageUrl']
                                        as String?)
                                    ?.toString();
                              }
                              final displayPath = imgPath ?? _profileImagePath;
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF064554).withOpacity(0.08),
                                  border: Border.all(
                                    color: const Color(0xFF064554)
                                        .withOpacity(0.15),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF064554).withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: displayPath != null &&
                                        File(displayPath).existsSync()
                                    ? ClipOval(
                                        child: Image.file(File(displayPath),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.person_rounded,
                                        color: Color(0xFF064554), size: 48),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _changeProfileImage,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF064554),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snap.hasData || !(snap.data?.exists ?? false)) {
                          // fallback to local values
                          return Column(
                            children: [
                              Text(_name.isNotEmpty ? _name : 'User',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 4),
                              Text(_email,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF9E9E9E))),
                              if (_profileLocationLabel.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(_profileLocationLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF616161))),
                              ],
                            ],
                          );
                        }

                        final data = snap.data!.data()! as Map<String, dynamic>;
                        final nameFromDoc =
                            (data['name'] ?? '').toString().trim();
                        final first =
                            (data['firstName'] ?? '').toString().trim();
                        final last = (data['lastName'] ?? '').toString().trim();
                        final email = (data['email'] ??
                                FirebaseAuth.instance.currentUser?.email ??
                                '')
                            .toString();
                        final phone = (data['phoneNumber'] ?? '').toString();
                        final city = (data['city'] ?? '').toString();

                        final displayName = nameFromDoc.isNotEmpty
                            ? nameFromDoc
                            : ((('$first $last').trim().isNotEmpty)
                                ? ('$first $last').trim()
                                : (email.isNotEmpty ? email : 'User'));

                        return Column(
                          children: [
                            Text(displayName,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A2E))),
                            const SizedBox(height: 4),
                            Text(email,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF9E9E9E))),
                            if (phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(phone,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ],
                            if (city.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(city,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF616161))),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Live stats (from Firestore)
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('reports')
                              .where('userId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                      builder: (context, snap) {
                        int total = 0;
                        int resolved = 0;
                        int inProgressCount = 0;
                        if (snap.hasData && snap.data != null) {
                          final docs = snap.data!.docs;
                          total = docs.length;
                          resolved = docs
                              .where((d) => (d.data()['status'] ?? '')
                                  .toString()
                                  .trim()
                                  .toLowerCase()
                                  .contains('resolv'))
                              .length;
                          inProgressCount = docs.where((doc) {
                            final s = (doc.data()['status'] ?? '')
                                .toString()
                                .trim()
                                .toLowerCase();
                            return s.contains('received') ||
                                s.contains('ai') ||
                                s.contains('verified') ||
                                s.contains('active') ||
                                s.contains('pending') ||
                                s.contains('in progress') ||
                                s.contains('assigned');
                          }).length;
                        }
                        final pts = inProgressCount;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: _miniStat('$total', 'Reports')),
                            _divider(),
                            Expanded(child: _miniStat('$resolved', 'Resolved')),
                            _divider(),
                            Expanded(child: _miniStat('$pts', 'Active')),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Contribution bar (computed from Firestore reports)
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('reports')
                              .where('userId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                      builder: (context, snap) {
                        int totalReports = 0;
                        int resolvedReports = 0;
                        if (snap.hasData && snap.data != null) {
                          final docs = snap.data!.docs;
                          totalReports = docs.length;
                          resolvedReports = docs.where((d) {
                            final status = (d.data()['status'] ?? '')
                                .toString()
                                .trim()
                                .toLowerCase();
                            return status == 'resolved';
                          }).length;
                        }

                        final double resolutionRate = totalReports > 0
                            ? (resolvedReports / totalReports)
                            : 0.0;
                        final int percentage = (resolutionRate * 100).round();

                        return _contributionBarWithRate(
                            resolutionRate, percentage);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Account ───────────────────────────────────────────────────
              _section('Account', [
                _tile(Icons.person_outline_rounded, 'Edit Profile',
                    const Color(0xFF064554), _editProfile),
                _tile(
                    Icons.notifications_outlined,
                    'Notifications',
                    const Color(0xFF9C27B0),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    )),
              ]),

              const SizedBox(height: 12),

              // ── My Activity ───────────────────────────────────────────────
              _section('My Activity', [
                _tile(
                    Icons.bar_chart_rounded,
                    'Report Statistics',
                    const Color(0xFF0288D1),
                    () => _showStats(context, provider)),
                _tile(
                    Icons.history_rounded,
                    'View All Reports',
                    const Color(0xFF43A047),
                    () => Navigator.pushNamed(context, '/all-reports')),
              ]),

              const SizedBox(height: 12),

              // ── Preferences ───────────────────────────────────────────────
              _section('Preferences', [
                _tile(Icons.help_outline_rounded, 'Help & Support',
                    const Color(0xFF43A047), () => _showHelp()),
              ]),

              const SizedBox(height: 12),

              // ── About ─────────────────────────────────────────────────────
              _section('About', [
                _tile(Icons.info_outline_rounded, 'About UrbanPulse',
                    const Color(0xFF064554), _showAbout),
                _tile(Icons.privacy_tip_outlined, 'Privacy Policy',
                    const Color(0xFF757575), _showPrivacyPolicy),
              ]),

              const SizedBox(height: 12),

              // ── Logout ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFE53935), size: 22),
                    label: const Text('Log Out',
                        style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935).withOpacity(0.08),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _contributionBar(ReportProvider p) {
    final pct = p.totalCount == 0
        ? 0.0
        : (p.resolvedCount / p.totalCount).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Resolution Rate',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500)),
            Text('${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF43A047),
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFE0E0E0),
            color: const Color(0xFF43A047),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  void _showStats(BuildContext context, ReportProvider p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseAuth.instance.currentUser == null
              ? const Stream.empty()
              : FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
          builder: (context, snap) {
            int total = 0;
            int active = 0;
            int resolved = 0;
            if (snap.hasData && snap.data != null) {
              final docs = snap.data!.docs;
              total = docs.length;
              active = docs.where((d) {
                final s =
                    (d.data()['status'] ?? '').toString().trim().toLowerCase();
                return s.contains('received') ||
                    s.contains('ai') ||
                    s.contains('verified') ||
                    s.contains('active') ||
                    s.contains('pending') ||
                    s.contains('in progress') ||
                    s.contains('assigned');
              }).length;
              resolved = docs
                  .where((d) => (d.data()['status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase()
                      .contains('resolv'))
                  .length;
            }
            final rate = total == 0
                ? '0%'
                : '${((resolved / total) * 100).toStringAsFixed(0)}%';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Report Statistics',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _statRow('Total Reports', '$total', const Color(0xFF064554)),
                _statRow(
                    'Active / In Progress', '$active', const Color(0xFFFB8C00)),
                _statRow('Resolved', '$resolved', const Color(0xFF43A047)),
                _statRow('Resolution Rate', rate, const Color(0xFF43A047)),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF424242)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    SnackBarHelper.showInfo(context, '$feature — coming soon!');
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & Support'),
        content: const Text(
          '📍 How to report an issue:\n'
          '1. Tap the green "Report Issue" button\n'
          '2. Add a photo as evidence\n'
          '3. Select the issue category\n'
          '4. Tap the location button to auto-detect GPS\n'
          '5. Add a description and submit\n\n'
          '🔔 Status updates:\n'
          'Track your report through\n Received → Verified → Assigned → Resolved\n\n'
          '💡 Tips for effective reporting:\n'
          '- Provide clear photos\n'
          '- Add detailed descriptions\n'
          '- Ensure GPS location is accurate',
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 13, height: 1.65),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(color: Color(0xFF064554))),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78909C))),
        ],
      );

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: const Color(0xFFE0E0E0),
        margin: const EdgeInsets.symmetric(horizontal: 24),
      );

  Widget _section(String title, List<Widget> items) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF90A4AE),
                      letterSpacing: 1.2)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(children: items),
              ),
            ),
          ],
        ),
      );

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF064554), size: 16),
                ),
              ],
            ),
          ),
        ),
      );
}
