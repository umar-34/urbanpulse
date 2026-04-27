import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/report_provider.dart';
import 'create_report_screen.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'John Doe';
  String _email = 'john.doe@example.com';
  String _phone = '';
  String? _profileImagePath;
  final _address1Ctrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  String? _locationError;
  String _profileLocationLabel = '';
  final Set<String> _invalidFields = <String>{};

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            physics: const ClampingScrollPhysics(),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _sheetField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _sheetField(emailCtrl, 'Email', Icons.email_outlined),
              const SizedBox(height: 14),
              _sheetField(phoneCtrl, 'Phone', Icons.phone_android_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final phoneVal = phoneCtrl.text.trim();
                    if (phoneVal.isNotEmpty && !RegExp(r'^03\d{9}\$').hasMatch(phoneVal)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Enter valid Pakistani mobile: 03XXXXXXXXX')));
                      return;
                    }
                    setState(() {
                      _name = nameCtrl.text.trim().isNotEmpty
                          ? nameCtrl.text.trim()
                          : _name;
                      _email = emailCtrl.text.trim().isNotEmpty
                          ? emailCtrl.text.trim()
                          : _email;
                      _phone = phoneVal; // allow empty to clear
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('profile_phone', _phone);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Changes',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              ]
              ),
              
            ),
          ),
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
            if (_profileImagePath != null) ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
              title: const Text('Remove Photo', style: TextStyle(color: Color(0xFFE53935))),
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('profile_image');
        setState(() => _profileImagePath = null);
        return;
      }
      final src = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final res = await MediaService.pickImage(source: src);
      if (res != null) {
        setState(() => _profileImagePath = res.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', res.path);
      }
    } catch (_) {}
  }

  Widget _sheetField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
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
                color: const Color(0xFF1565C0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_city_rounded,
                  color: Color(0xFF1565C0), size: 20),
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
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF424242)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: Color(0xFF1565C0))),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Logged out successfully'),
                  backgroundColor: const Color(0xFF1565C0),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('profile_city') ?? '';
    final area = prefs.getString('profile_area') ?? '';
    final street = prefs.getString('profile_street') ?? '';
    final lat = prefs.getDouble('profile_lat');
    final lon = prefs.getDouble('profile_lon');
    final phone = prefs.getString('profile_phone') ?? '';
    final img = prefs.getString('profile_image');
    setState(() {
      if (street.isNotEmpty) _streetCtrl.text = street;
      if (area.isNotEmpty) _areaCtrl.text = area;
      if (city.isNotEmpty) _cityCtrl.text = city;
      if (lat != null) _latitude = lat;
      if (lon != null) _longitude = lon;
      _phone = phone;
      _profileImagePath = img;
      // Prefer Street + City for profile label, fallback to Area + City, then City
      if (street.isNotEmpty && city.isNotEmpty) {
        _profileLocationLabel = '$street, $city';
      } else if (area.isNotEmpty && city.isNotEmpty) {
        _profileLocationLabel = '$area, $city';
      } else if (city.isNotEmpty) {
        _profileLocationLabel = city;
      } else {
        _profileLocationLabel = '';
      }
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
              left: 16, right: 16, top: 12, bottom: media.viewInsets.bottom + 12),
          child: StatefulBuilder(builder: (context, setState) {
            Future<void> _fetchLocation() async {
              setState(() {
                _locating = true;
                _locationError = null;
              });
              try {
                final res = await LocationService.getCurrentLocation();
                // Derive city and area only for profile display
                String city = '';
                String area = '';
                try {
                  final parts = await LocationService.reverseGeocodeParts(res.latitude, res.longitude);
                  final fetchedStreet = parts['street'] ?? '';
                  final fetchedSub = parts['subLocality'] ?? '';
                  final fetchedCity = parts['locality'] ?? '';
                  // Assign using priority: street -> subLocality for street field
                  String streetVal = fetchedStreet;
                  if (streetVal.isEmpty && fetchedSub.isNotEmpty) streetVal = fetchedSub;
                  // Populate local variables
                  city = fetchedCity;
                  area = fetchedSub;
                  // If area equals city, ignore area
                  if (area.isNotEmpty && city.isNotEmpty && area.toLowerCase() == city.toLowerCase()) {
                    area = '';
                  }
                  // Apply to visible fields below
                  if (streetVal.isNotEmpty) _streetCtrl.text = streetVal;
                } catch (_) {}

                setState(() {
                  _latitude = res.latitude;
                  _longitude = res.longitude;
                  // Populate the separate fields if available
                  if (area.isNotEmpty) _areaCtrl.text = area;
                  if (city.isNotEmpty) _cityCtrl.text = city;
                  _locating = false;
                });
              } catch (e) {
                setState(() {
                  _locationError = e.toString();
                  _locating = false;
                });
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const Text('Update Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                // Manual inputs: Street, City (searchable), Landmark
                TextField(
                  controller: _streetCtrl,
                  onChanged: (v) {
                    if (v.trim().isNotEmpty && _invalidFields.remove('street')) {
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Street Address *',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    errorText: _invalidFields.contains('street') ? 'Required' : null,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _invalidFields.contains('street') ? const Color(0xFFB71C1C) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _invalidFields.contains('street') ? const Color(0xFFB71C1C) : const Color(0xFF1565C0),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // show searchable city picker (uses PUNJAB_CITIES)
                    showModalBottomSheet<void>(
                      context: ctx,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (cctx) {
                        final media = MediaQuery.of(cctx);
                        return SizedBox(
                          height: media.size.height * 0.7,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: media.viewInsets.bottom + 12),
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
                                const Text('Search City', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Builder(builder: (context) {
                                  final TextEditingController searchCtrl = TextEditingController();
                                  List<String> filtered = List.from(PUNJAB_CITIES);
                                  return Expanded(
                                    child: StatefulBuilder(builder: (context, setState) {
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
                                              setState(() {
                                                filtered = PUNJAB_CITIES.where((c) => c.toLowerCase().contains(qq)).toList();
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: ListView.separated(
                                              itemCount: filtered.length,
                                              separatorBuilder: (_, __) => const Divider(height: 1),
                                              itemBuilder: (context, i) {
                                                final city = filtered[i];
                                                return ListTile(
                                                  title: Text(city),
                                                  onTap: () {
                                                    setState(() {
                                                      _cityCtrl.text = city;
                                                    });
                                                    Navigator.of(cctx).pop();
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
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _cityCtrl,
                      onChanged: (v) {
                        if (v.trim().isNotEmpty && _invalidFields.remove('city')) {
                          setState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'City *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        errorText: _invalidFields.contains('city') ? 'Required' : null,
                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _invalidFields.contains('city') ? const Color(0xFFB71C1C) : const Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _invalidFields.contains('city') ? const Color(0xFFB71C1C) : const Color(0xFF1565C0),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _landmarkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Landmark',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_locationError!, style: const TextStyle(color: Color(0xFFE53935))),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                          onPressed: () async {
                            final streetVal = _streetCtrl.text.trim();
                            final cityVal = _cityCtrl.text.trim();
                            _invalidFields.remove('street');
                            _invalidFields.remove('city');
                            if (streetVal.isEmpty || cityVal.isEmpty) {
                              if (streetVal.isEmpty) _invalidFields.add('street');
                              if (cityVal.isEmpty) _invalidFields.add('city');
                              setState(() {});
                              return;
                            }
                            final prefs = await SharedPreferences.getInstance();
                            final existingStreet = prefs.getString('profile_street') ?? '';
                            final existingCity = prefs.getString('profile_city') ?? '';
                            final wouldOverwrite = (existingStreet.isNotEmpty && existingStreet != streetVal) || (existingCity.isNotEmpty && existingCity != cityVal);
                            if (wouldOverwrite) {
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirm overwrite'),
                                  content: const Text('You already have a saved Street/City. Do you want to overwrite it?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Overwrite')),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                            }
                            await prefs.setString('profile_city', cityVal);
                            await prefs.setString('profile_area', _areaCtrl.text.trim());
                            await prefs.setString('profile_street', streetVal);
                            if (_latitude != null) await prefs.setDouble('profile_lat', _latitude!);
                            if (_longitude != null) await prefs.setDouble('profile_lon', _longitude!);
                            this.setState(() {
                              if (streetVal.isNotEmpty && cityVal.isNotEmpty) {
                                _profileLocationLabel = '$streetVal, $cityVal';
                              } else if (_areaCtrl.text.trim().isNotEmpty && cityVal.isNotEmpty) {
                                _profileLocationLabel = '${_areaCtrl.text.trim()}, $cityVal';
                              } else if (cityVal.isNotEmpty) {
                                _profileLocationLabel = cityVal;
                              } else {
                                _profileLocationLabel = '';
                              }
                            });
                            await prefs.setString('profile_phone', _phone);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated')));
                          },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Location'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
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
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Profile',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFEEEEEE)),
            ),
          ),
          body: ListView(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _changeProfileImage,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                              border: Border.all(
                                color: const Color(0xFF1565C0).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: _profileImagePath != null && File(_profileImagePath!).existsSync()
                                ? ClipOval(
                                    child: Image.file(File(_profileImagePath!), width: 88, height: 88, fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.person_rounded,
                                    color: Color(0xFF1565C0), size: 44),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _changeProfileImage,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(_name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 4),
                    Text(_email,
                      style: const TextStyle(
                        fontSize: 13, color: Color(0xFF9E9E9E))),
                    if (_phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(_phone,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF616161))),
                    ],
                    if (_profileLocationLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(_profileLocationLabel,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF616161))),
                    ],
                    const SizedBox(height: 20),
                    // Live stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _miniStat('${provider.totalCount}', 'Reports'),
                        _divider(),
                        _miniStat('${provider.resolvedCount}', 'Resolved'),
                        _divider(),
                        _miniStat('$points', 'Points'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Contribution bar
                    _contributionBar(provider),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Account ───────────────────────────────────────────────────
              _section('Account', [
                _tile(Icons.person_outline_rounded, 'Edit Profile',
                    const Color(0xFF1565C0), _editProfile),
                _tile(
                    Icons.notifications_outlined,
                    'Notifications',
                    const Color(0xFF9C27B0),
                    () => _showComingSoon('Notifications')),
                _tile(
                  Icons.location_on_outlined,
                  'Location Settings',
                  const Color(0xFFE53935),
                  () => _showLocationSettings()),
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
                _tile(Icons.language_outlined, 'Language',
                    const Color(0xFF0288D1), () => _showComingSoon('Language')),
                _tile(Icons.help_outline_rounded, 'Help & Support',
                    const Color(0xFF43A047), () => _showHelp()),
              ]),

              const SizedBox(height: 12),

              // ── About ─────────────────────────────────────────────────────
              _section('About', [
                _tile(Icons.info_outline_rounded, 'About UrbanPulse',
                    const Color(0xFF1565C0), _showAbout),
                _tile(
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    const Color(0xFF757575),
                    () => _showComingSoon('Privacy Policy')),
                _tile(
                    Icons.star_outline_rounded,
                    'Rate the App',
                    const Color(0xFFFB8C00),
                    () => _showComingSoon('Rate the App')),
              ]),

              const SizedBox(height: 12),

              // ── Logout ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFE53935)),
                    label: const Text('Log Out',
                        style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFE53935), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Statistics',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _statRow(
                'Total Reports', '${p.totalCount}', const Color(0xFF1565C0)),
            _statRow('Active / In Progress', '${p.activeCount}',
                const Color(0xFFFB8C00)),
            _statRow('Resolved', '${p.resolvedCount}', const Color(0xFF43A047)),
            _statRow(
                'Resolution Rate',
                p.totalCount == 0
                    ? '0%'
                    : '${((p.resolvedCount / p.totalCount) * 100).toStringAsFixed(0)}%',
                const Color(0xFF43A047)),
            const SizedBox(height: 8),
          ],
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — coming soon!'),
      backgroundColor: const Color(0xFF1565C0),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
          '2. Add a photo or video as evidence\n'
          '3. Select the issue category\n'
          '4. Tap the location button to auto-detect GPS\n'
          '5. Add a description and submit\n\n'
          '🔔 Status updates:\n'
          'Track your report through Received → AI Verified → Assigned → Resolved\n\n'
          '💬 Comments:\n'
          'Open any report to add comments or request updates.',
          style: TextStyle(fontSize: 13, height: 1.65),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(color: Color(0xFF1565C0))),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1565C0))),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ],
      );

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: const Color(0xFFE0E0E0),
        margin: const EdgeInsets.symmetric(horizontal: 20),
      );

  Widget _section(String title, List<Widget> items) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9E9E9E),
                      letterSpacing: 0.8)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(children: items),
            ),
          ],
        ),
      );

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E))),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Color(0xFFBDBDBD), size: 20),
        onTap: onTap,
      );
}
