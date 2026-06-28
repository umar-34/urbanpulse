import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../utils/snackbar_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';

const List<String> PUNJAB_CITIES = [
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
  "Wah Cantt"
];

class _Cat {
  final IssueCategory category;
  final IconData icon;
  final String label;
  const _Cat(this.category, this.icon, this.label);
}

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  IssueCategory? _selectedCategory;
  final _descriptionCtrl = TextEditingController();
  final _address1Ctrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  final List<String> _imagePaths = [];
  // videos removed: only images allowed

  double? _latitude;
  double? _longitude;
  bool _locating = false;
  String? _locationError;

  bool _isSubmitting = false;
  final Set<String> _invalidFields = <String>{};
  String? _topErrorMsg;
  Timer? _topErrorTimer;
  bool _initializedFromArgs = false;

  final _categories = const [
    _Cat(IssueCategory.pothole, Icons.warning_amber_rounded, 'Pothole'),
    _Cat(IssueCategory.garbage, Icons.delete_outline_rounded, 'Garbage'),
    _Cat(IssueCategory.brokenStreetlight, Icons.lightbulb_outline_rounded,
        'Streetlight'),
    _Cat(IssueCategory.waterLeak, Icons.water_drop_outlined, 'Water Leak'),
    _Cat(IssueCategory.other, Icons.more_horiz_rounded, 'Other'),
  ];

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _address1Ctrl.dispose();
    _streetCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _landmarkCtrl.dispose();
    _topErrorTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) {
        try {
          final cat = IssueCategory.values.firstWhere((e) => e.name == arg,
              orElse: () => IssueCategory.other);
          setState(() {
            _selectedCategory = cat;
          });
        } catch (_) {}
      }
      _initializedFromArgs = true;
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Evidence',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _mediaOption(Icons.camera_alt_rounded, 'Take Photo', () async {
                Navigator.pop(context);
                final ok = await _ensureCameraPermission();
                if (!ok) {
                  _showSnack('Camera permission denied.');
                  return;
                }
                await _pick(ImageSource.camera, closeModal: false);
              }),
              _mediaOption(
                  Icons.photo_library_rounded, 'Choose Images from Gallery',
                  () async {
                Navigator.pop(context);
                final ok = await _ensureGalleryPermission();
                if (!ok) {
                  _showSnack('Gallery permission denied.');
                  return;
                }
                await _pickMultipleImages(closeModal: false);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final proceed = await _showPermissionRationale(
        'Camera Permission', 'The app needs camera access to take photos.');
    if (!proceed) return false;

    final res = await Permission.camera.request();
    if (res.isGranted) return true;

    if (res.isPermanentlyDenied) {
      await _showOpenSettingsDialog('Camera Permission',
          'Camera permission is permanently denied. Open settings to enable it.');
    }
    return false;
  }

  Future<bool> _ensureGalleryPermission() async {
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      final photosStatus = await Permission.photos.status;
      if (storageStatus.isGranted || photosStatus.isGranted) return true;

      final proceed = await _showPermissionRationale('Storage Permission',
          'The app needs storage access to select photos from your gallery.');
      if (!proceed) return false;

      final resStorage = await Permission.storage.request();
      if (resStorage.isGranted) return true;

      final resPhotos = await Permission.photos.request();
      if (resPhotos.isGranted) return true;

      if (resStorage.isPermanentlyDenied || resPhotos.isPermanentlyDenied) {
        await _showOpenSettingsDialog('Storage Permission',
            'Storage permission is permanently denied. Open settings to enable it.');
      }
      return false;
    } else {
      final status = await Permission.photos.status;
      if (status.isGranted) return true;

      final proceed = await _showPermissionRationale('Photos Permission',
          'The app needs Photos access to select images from your gallery.');
      if (!proceed) return false;

      final res = await Permission.photos.request();
      if (res.isGranted) return true;
      if (res.isPermanentlyDenied) {
        await _showOpenSettingsDialog('Photos Permission',
            'Photos permission is permanently denied. Open settings to enable it.');
      }
      return false;
    }
  }

  Future<bool> _showPermissionRationale(String title, String message) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed')),
        ],
      ),
    );
    return res == true;
  }

  Future<bool> _showOpenSettingsDialog(String title, String message) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.pop(context, true);
                await openAppSettings();
              },
              child: const Text('Open Settings')),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _pickMultipleImages({bool closeModal = true}) async {
    if (closeModal) Navigator.pop(context);
    try {
      final results = await MediaService.pickImagesFromGallery();
      if (results != null && results.isNotEmpty) {
        final picked = results.map((r) => r.path).toList();
        if (picked.length > 4) {
          _showSnack('Please select up to 4 images only.', fields: ['media']);
          return;
        }
        for (final p in picked) {
          final f = File(p);
          if (f.existsSync() && f.lengthSync() > 5 * 1024 * 1024) {
            _showSnack('Each image must be <= 5MB.', fields: ['media']);
            return;
          }
        }
        setState(() {
          final remaining = 4 - _imagePaths.length;
          _imagePaths.addAll(picked.take(remaining));
          _invalidFields.remove('media');
          if (_invalidFields.isEmpty) _topErrorMsg = null;
        });
      }
    } catch (e) {
      _showSnack('Could not access gallery: $e');
    }
  }

  Future<void> _pick(ImageSource source, {bool closeModal = true}) async {
    if (closeModal) Navigator.pop(context);
    try {
      final result = await MediaService.pickImage(source: source);
      if (result != null) {
        final f = File(result.path);
        if (f.existsSync() && f.lengthSync() > 5 * 1024 * 1024) {
          _showSnack('Image must be <= 5MB.', fields: ['media']);
          return;
        }
        if (_imagePaths.length >= 4) {
          _showSnack('You can attach up to 4 images only.', fields: ['media']);
          return;
        }
        setState(() {
          _imagePaths.add(result.path);
          _invalidFields.remove('media');
          if (_invalidFields.isEmpty) _topErrorMsg = null;
        });
      }
    } catch (e) {
      _showSnack('Could not access media: $e');
    }
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final result = await LocationService.getCurrentLocation();
      String area = '';
      String city = '';
      try {
        final rev = await LocationService.reverseGeocode(
            result.latitude, result.longitude);
        if (rev.isNotEmpty) {
          final parts = rev
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) city = parts.last;
          if (parts.length >= 2) area = parts.first;
          if (area.isNotEmpty &&
              city.isNotEmpty &&
              area.toLowerCase() == city.toLowerCase()) {
            area = '';
          }
        }
      } catch (_) {}

      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        if (area.isNotEmpty && city.isNotEmpty) {
          _address1Ctrl.text = '$area, $city';
        } else if (city.isNotEmpty) {
          _address1Ctrl.text = city;
        } else {
          _address1Ctrl.text = '';
        }
        if (area.isNotEmpty) _areaCtrl.text = area;
        if (city.isNotEmpty) _cityCtrl.text = city;
        _invalidFields.removeAll(['address1', 'area', 'city']);
        if (_invalidFields.isEmpty) _topErrorMsg = null;
        _locating = false;
      });
    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _locating = false;
      });
      _showSnack(_locationError!, fields: ['address1']);
    }
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      _showSnack('Please select an issue category.', fields: ['category']);
      return;
    }
    // media validation: require 2-4 images
    if (_imagePaths.isEmpty) {
      _showSnack('Please add images as evidence.', fields: ['media']);
      return;
    }
    if (_imagePaths.length < 2) {
      _showSnack('Please attach at least 2 images.', fields: ['media']);
      return;
    }
    if (_imagePaths.length > 4) {
      _showSnack('You can attach up to 4 images only.', fields: ['media']);
      return;
    }
    for (final p in _imagePaths) {
      final f = File(p);
      if (f.existsSync() && f.lengthSync() > 5 * 1024 * 1024) {
        _showSnack('Each image must be <= 5MB.', fields: ['media']);
        return;
      }
    }
    final autoFetched = _address1Ctrl.text.trim().isNotEmpty;
    if (!autoFetched) {
      _invalidFields.add('address1');
      setState(() {});
      _showSnack('Please fetch location using the Geo Location button.',
          fields: ['address1']);
      return;
    }

    if (_areaCtrl.text.trim().isEmpty) {
      _invalidFields.add('area');
      setState(() {});
      _showSnack('Please provide Area.', fields: ['area']);
      return;
    }
    if (_cityCtrl.text.trim().isEmpty) {
      _invalidFields.add('city');
      setState(() {});
      _showSnack('Please provide City.', fields: ['city']);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uploadFutures = _imagePaths
          .map((path) => CloudinaryService.uploadImage(path))
          .toList();
      final uploadResults = await Future.wait(uploadFutures);

      final imageUrls = uploadResults.whereType<String>().toList();

      // Primary image URL (first successfully uploaded image)
      final primaryImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

      if (!mounted) return;

      // ── Step B: Build location string ───────────────────────────────────
      final locationParts = <String>[];
      if (_address1Ctrl.text.trim().isNotEmpty) {
        locationParts.add(_address1Ctrl.text.trim());
      } else if (_streetCtrl.text.trim().isNotEmpty) {
        locationParts.add(_streetCtrl.text.trim());
      }
      locationParts.add(_areaCtrl.text.trim());
      locationParts.add(_cityCtrl.text.trim());
      if (_landmarkCtrl.text.trim().isNotEmpty) {
        locationParts.add('Near ${_landmarkCtrl.text.trim()}');
      }

      final report = Report(
        id: const Uuid().v4(),
        title: _selectedCategory!.label,
        category: _selectedCategory!,
        location: locationParts.join(', '),
        latitude: _latitude,
        longitude: _longitude,
        status: ReportStatus.received,
        createdAt: DateTime.now(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        mediaPath: primaryImageUrl,
        isVideo: false,
        updates: [
          ReportUpdate(
            message: 'Report received and queued for AI verification.',
            timestamp: DateTime.now(),
            isOfficial: true,
          ),
        ],
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final data = {
        'id': report.id,
        'title': report.title,
        'category': report.category.name,
        'location': report.location,
        'latitude': report.latitude,
        'longitude': report.longitude,
        'status': 'Received',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': uid,
        'description': report.description,
        'imageUrl': primaryImageUrl,
        // Full list of uploaded image URLs
        'imageUrls': imageUrls,
        'isVideo': report.isVideo,
        'updates': report.updates.map((u) => u.toJson()).toList(),
      };

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(report.id)
          .set(data);

      // ── Step D: Send 'Report Received' notification ──────────────────────
      if (uid != null) {
        await NotificationService.sendNotification(
          userId: uid,
          reportId: report.id,
          title: 'Report Received',
          body:
              'Your "${report.title}" report has been received and is queued for verification.',
        );
      }

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Report submitted successfully.');
      _showSuccessDialog(report.id);
    } catch (e) {
      // ignore: avoid_print
      print('REPORT SUBMIT ERROR: $e');
      if (!mounted) return;
      SnackBarHelper.showError(
          context, 'Failed to submit report: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                // Search and list (stateful inside the sheet)

                Builder(builder: (context) {
                  final TextEditingController searchCtrl =
                      TextEditingController();
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
                                filtered = PUNJAB_CITIES
                                    .where((c) => c.toLowerCase().contains(qq))
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
                                    setState(() {
                                      _cityCtrl.text = city;
                                      _invalidFields.remove('city');
                                      if (_invalidFields.isEmpty) {
                                        _topErrorMsg = null;
                                      }
                                    });
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

  void _showSnack(String msg, {List<String>? fields}) {
    _topErrorTimer?.cancel();
    setState(() {
      _topErrorMsg = msg;
      _invalidFields.clear();
      if (fields != null) _invalidFields.addAll(fields);
    });
    _topErrorTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _topErrorMsg = null;
        _invalidFields.clear();
      });
    });
  }

  void _showSuccessDialog(String reportId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF43A047), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Report Submitted!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            const Text(
              'Your report is being verified.\nYou\'ll receive updates shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF757575), height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF064554)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Home',
                        style: TextStyle(color: Color(0xFF064554))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/report-detail',
                          arguments: reportId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF064554),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('View Report',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F8),
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
        title: const Text('Create Report',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Step 1: Photo/Video ──────────────────────────────────────────
              _sectionLabel('Step 1 â€¢ Evidence'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: GestureDetector(
                    onTap: _showMediaPicker,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 180,
                      decoration: BoxDecoration(
                        color: _imagePaths.isNotEmpty
                            ? const Color(0xFF064554).withOpacity(0.10)
                            : Colors.white.withOpacity(0.62),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _imagePaths.isNotEmpty
                              ? const Color(0xFF064554).withOpacity(0.4)
                              : (_invalidFields.contains('media')
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFF064554).withOpacity(0.14)),
                          width: _imagePaths.isNotEmpty ? 2 : 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 14,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: _imagePaths.isNotEmpty
                          ? _mediaPreview()
                          : _mediaPlaceholder(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // ── Step 2: Category ─────────────────────────────────────────────
              _sectionLabel('Step 2 â€¢ Issue Category'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _invalidFields.contains('category') &&
                                _selectedCategory == null
                            ? const Color(0xFFB71C1C)
                            : const Color(0xFF064554).withOpacity(0.14),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: _categories.map((cat) {
                        final sel = _selectedCategory == cat.category;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedCategory = cat.category;
                              _invalidFields.remove('category');
                              if (_invalidFields.isEmpty) _topErrorMsg = null;
                            }),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? const Color(0xFF064554)
                                        : const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: sel
                                            ? const Color(0xFF064554)
                                            : const Color(0xFFE0E0E0)),
                                  ),
                                  child: Icon(cat.icon,
                                      color: sel
                                          ? Colors.white
                                          : const Color(0xFF616161),
                                      size: 24),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      cat.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: sel
                                            ? const Color(0xFF064554)
                                            : const Color(0xFF757575),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // ── Step 3: Location ─────────────────────────────────────────────
              _sectionLabel('Step 3 â€¢ Location'),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 8),
                child: Text('Location Details',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF064554).withOpacity(0.14),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _address1Ctrl,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Geo Location',
                                  hintText: 'Click the GPS icon',
                                  errorText: _invalidFields.contains('address1')
                                      ? 'Required'
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color:
                                            _invalidFields.contains('address1')
                                                ? const Color(0xFFB71C1C)
                                                : const Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color:
                                            _invalidFields.contains('address1')
                                                ? const Color(0xFFB71C1C)
                                                : const Color(0xFF064554)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 48,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF064554)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF064554)
                                            .withOpacity(0.14),
                                        width: 1.1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap:
                                            _locating ? null : _fetchLocation,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Center(
                                            child: _locating
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                                0xFF064554)))
                                                : const Icon(
                                                    Icons.my_location_rounded,
                                                    color: Color(0xFF064554)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _streetCtrl,
                          decoration: InputDecoration(
                            labelText: 'Street Address',
                            hintText: 'Street name, building number (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF064554)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _areaCtrl,
                                onChanged: (v) {
                                  if (v.trim().isNotEmpty &&
                                      _invalidFields.remove('area')) {
                                    setState(() {
                                      if (_invalidFields.isEmpty) {
                                        _topErrorMsg = null;
                                      }
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Area *',
                                  hintText: 'Neighborhood / area',
                                  errorText: _invalidFields.contains('area')
                                      ? 'Required'
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: _invalidFields.contains('area')
                                            ? const Color(0xFFB71C1C)
                                            : const Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: _invalidFields.contains('area')
                                            ? const Color(0xFFB71C1C)
                                            : const Color(0xFF064554)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _cityCtrl,
                                readOnly: true,
                                onTap: _showCityPicker,
                                decoration: InputDecoration(
                                  labelText: 'City *',
                                  hintText: 'City',
                                  errorText: _invalidFields.contains('city')
                                      ? 'Required'
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                  suffixIcon: const Icon(Icons.search),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: _invalidFields.contains('city')
                                            ? const Color(0xFFB71C1C)
                                            : const Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: _invalidFields.contains('city')
                                            ? const Color(0xFFB71C1C)
                                            : const Color(0xFF064554)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _landmarkCtrl,
                          decoration: InputDecoration(
                            labelText: 'Landmark',
                            hintText: 'Nearby landmark (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                        if (_locationError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _locationError!,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFE53935)),
                            ),
                          ),
                        if (_latitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 14, color: Color(0xFF43A047)),
                                const SizedBox(width: 4),
                                Text(
                                  'GPS: ${_latitude!.toStringAsFixed(5)}, '
                                  '${_longitude!.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF43A047)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // ── Step 4: Description ──────────────────────────────────────────
              _sectionLabel('Step 4 â€¢ Description (Optional)'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF064554).withOpacity(0.14),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _descriptionCtrl,
                      maxLines: 4,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: const InputDecoration(
                        hintText: 'Add a brief description (optional)...',
                        hintStyle:
                            TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              GestureDetector(
                onTap: _isSubmitting ? null : _submitReport,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF064554).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF064554).withOpacity(0.14),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Color(0xFF064554)))
                          : const Text('Submit Report',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF064554))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
          if (_topErrorMsg != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 5,
              left: 20,
              right: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_topErrorMsg!,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaPreview() {
    // Images grid preview (up to 4 images)

    return LayoutBuilder(builder: (context, constraints) {
      const double gridPadding = 8; // padding applied to GridView
      const double crossSpacing = 8; // horizontal spacing between columns
      const double mainSpacing = 8; // vertical spacing between rows
      const double totalHPadding =
          (gridPadding * 2) + crossSpacing; // left+right + inter-column
      const double totalVSpacing =
          (gridPadding * 2) + mainSpacing; // top+bottom + inter-row
      final cellWidth = (constraints.maxWidth - totalHPadding) / 2;
      final cellHeight = (constraints.maxHeight - totalVSpacing) / 2;
      final childAspect = cellWidth / cellHeight;
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspect,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index < _imagePaths.length) {
            final path = _imagePaths[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFB0BEC5))),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _imagePaths.removeAt(index);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            );
          }

          // empty slot: show add button
          return GestureDetector(
            onTap: () async {
              _showMediaPicker();
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 28, color: Color(0xFF064554)),
                    SizedBox(height: 6),
                    Text('Add',
                        style: TextStyle(
                            color: Color(0xFF064554),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _mediaPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF064554).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: Color(0xFF064554), size: 28),
        ),
        const SizedBox(height: 12),
        const Text('Add Photo',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF064554))),
        const SizedBox(height: 6),
        const Text('Tap to capture or upload from gallery',
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
                onTap: () async {
                  final ok = await _ensureCameraPermission();
                  if (!ok) {
                    _showSnack('Camera permission denied.');
                    return;
                  }
                  await _pick(ImageSource.camera, closeModal: false);
                },
                child: _mediaBtn(Icons.camera_alt_outlined, 'Camera')),
            const SizedBox(width: 12),
            GestureDetector(
                onTap: () async {
                  final ok = await _ensureGalleryPermission();
                  if (!ok) {
                    _showSnack('Gallery permission denied.');
                    return;
                  }
                  await _pickMultipleImages(closeModal: false);
                },
                child: _mediaBtn(Icons.photo_library_outlined, 'Gallery')),
          ],
        ),
      ],
    );
  }

  Widget _mediaBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF064554).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF064554).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF064554)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF064554),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xFF0a6378), width: 4)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1B3E),
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF064554).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF064554), size: 22),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
