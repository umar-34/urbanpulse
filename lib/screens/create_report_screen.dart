import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';

const List<String> PUNJAB_CITIES = [
  "Lahore",
  "Faisalabad",
  "Rawalpindi",
  "Gujranwala",
  "Multan",
  "Bahawalpur",
  "Sargodha",
  "Sialkot",
  "Sheikhupura",
  "Rahim Yar Khan",
  "Jhang",
  "Dera Ghazi Khan",
  "Gujrat",
  "Sahiwal",
  "Wah Cantt",
  "Taxila",
  "Mianwali",
  "Kasur",
  "Bhakkar",
  "Okara",
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
  String? _videoPath;

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
              _mediaOption(Icons.camera_alt_rounded, 'Take Photo',
                  () => _pick(ImageSource.camera, false)),
              _mediaOption(Icons.videocam_rounded, 'Record Video',
                  () => _pick(ImageSource.camera, true)),
              _mediaOption(Icons.photo_library_rounded,
                  'Choose Images from Gallery', () => _pickMultipleImages()),
              _mediaOption(
                  Icons.video_library_rounded,
                  'Choose Video from Gallery',
                  () => _pick(ImageSource.gallery, true)),
            ],
          ),
        ),
      ),
    );
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
          _videoPath = null;
          _invalidFields.remove('media');
          if (_invalidFields.isEmpty) _topErrorMsg = null;
        });
      }
    } catch (e) {
      _showSnack('Could not access gallery: $e');
    }
  }

  Future<void> _pick(ImageSource source, bool video) async {
    Navigator.pop(context);
    try {
      final result = video
          ? await MediaService.pickVideo(source: source)
          : await MediaService.pickImage(source: source);
      if (result != null) {
        setState(() {
          if (result.isVideo) {
            final f = File(result.path);
            if (f.existsSync() && f.lengthSync() > 100 * 1024 * 1024) {
              _showSnack('Video must be <= 100MB.', fields: ['media']);
              return;
            }
            _videoPath = result.path;
            _imagePaths.clear();
          } else {
            final f = File(result.path);
            if (f.existsSync() && f.lengthSync() > 5 * 1024 * 1024) {
              _showSnack('Image must be <= 5MB.', fields: ['media']);
              return;
            }
            if (_imagePaths.length >= 4) {
              _showSnack('You can attach up to 4 images only.',
                  fields: ['media']);
              return;
            }
            _imagePaths.add(result.path);
            _videoPath = null;
          }
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
      // Try to get cleaned area,city from reverse geocode (subLocality/locality)
      String area = '';
      String city = '';
      try {
        final rev = await LocationService.reverseGeocode(result.latitude, result.longitude);
        if (rev.isNotEmpty) {
          final parts = rev.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (parts.isNotEmpty) city = parts.last;
          if (parts.length >= 2) area = parts.first;
          // avoid duplicate city in area field
          if (area.isNotEmpty && city.isNotEmpty && area.toLowerCase() == city.toLowerCase()) {
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
        _invalidFields.removeAll(['address1', 'street', 'area', 'city']);
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
    // media validation: require either 2-5 images or exactly 1 video
    if ((_videoPath == null) && _imagePaths.isEmpty) {
      _showSnack('Please add a photo or video as evidence.', fields: ['media']);
      return;
    }
    if (_videoPath != null && _imagePaths.isNotEmpty) {
      _showSnack('Please attach either images or a video, not both.',
          fields: ['media']);
      return;
    }
    if (_imagePaths.isNotEmpty) {
      if (_imagePaths.length < 2) {
        _showSnack('Please attach at least 2 images.', fields: ['media']);
        return;
      }
      if (_imagePaths.length > 5) {
        _showSnack('You can attach up to 5 images only.', fields: ['media']);
        return;
      }
      for (final p in _imagePaths) {
        final f = File(p);
        if (f.existsSync() && f.lengthSync() > 5 * 1024 * 1024) {
          _showSnack('Each image must be <= 5MB.', fields: ['media']);
          return;
        }
      }
    }
    if (_videoPath != null) {
      final f = File(_videoPath!);
      if (f.existsSync() && f.lengthSync() > 100 * 1024 * 1024) {
        _showSnack('Video must be <= 100MB.', fields: ['media']);
        return;
      }
    }
    // Address validation: user must use either auto-fetch OR manual inputs (street+area+city)
    final autoFetched = _address1Ctrl.text.trim().isNotEmpty;
    if (!autoFetched) {
      // require manual fields
      if (_streetCtrl.text.trim().isEmpty) {
        _showSnack('Please provide Street Address or use auto-fetch.',
            fields: ['street']);
        return;
      }
      if (_areaCtrl.text.trim().isEmpty) {
        _showSnack('Please provide Area.', fields: ['area']);
        return;
      }
      if (_cityCtrl.text.trim().isEmpty) {
        _showSnack('Please provide City.', fields: ['city']);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    // Simulate AI verification delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

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
      // For now we save the primary media path (first image or video) to the model
      mediaPath:
          _videoPath ?? (_imagePaths.isNotEmpty ? _imagePaths.first : null),
      isVideo: _videoPath != null,
      updates: [
        ReportUpdate(
          message: 'Report received and queued for AI verification.',
          timestamp: DateTime.now(),
          isOfficial: true,
        ),
      ],
    );

    await context.read<ReportProvider>().addReport(report);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showSuccessDialog(report.id);
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

                // Keep controllers/state outside the inner builder so they persist
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
              'Your report is being AI verified.\nYou\'ll receive updates shortly.',
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
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Home',
                        style: TextStyle(color: Color(0xFF1565C0))),
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
                      backgroundColor: const Color(0xFF1565C0),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Create Report',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Step 1: Photo/Video ──────────────────────────────────────────
              _sectionLabel('Step 1 • Evidence'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showMediaPicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 180,
                  decoration: BoxDecoration(
                    color: (_videoPath != null || _imagePaths.isNotEmpty)
                        ? const Color(0xFF1565C0).withOpacity(0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (_videoPath != null || _imagePaths.isNotEmpty)
                          ? const Color(0xFF1565C0).withOpacity(0.4)
                          : _invalidFields.contains('media')
                              ? const Color(0xFFB71C1C)
                              : const Color(0xFFE0E0E0),
                      width: (_videoPath != null || _imagePaths.isNotEmpty)
                          ? 2
                          : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: (_videoPath != null || _imagePaths.isNotEmpty)
                      ? _mediaPreview()
                      : _mediaPlaceholder(),
                ),
              ),

              const SizedBox(height: 24),
              // ── Step 2: Category ─────────────────────────────────────────────
              _sectionLabel('Step 2 • Issue Category'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _invalidFields.contains('category') &&
                              _selectedCategory == null
                          ? const Color(0xFFB71C1C)
                          : Colors.transparent),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
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
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: sel
                                        ? const Color(0xFF1565C0)
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  cat.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        sel ? FontWeight.w700 : FontWeight.w400,
                                    color: sel
                                        ? const Color(0xFF1565C0)
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

              const SizedBox(height: 24),
              // ── Step 3: Location ─────────────────────────────────────────────
              _sectionLabel('Step 3 • Location'),
              const SizedBox(height: 10),
              // Heading above both auto-fetch and manual inputs
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 8),
                child: Text('Location Details',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1)),
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
                              labelText: 'Auto Fetch',
                              hintText: 'Press button to fetch location.',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: _invalidFields.contains('address1')
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: _invalidFields.contains('address1')
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFF1565C0)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _locating ? null : _fetchLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _locating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Or between auto fetch and manual input
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('Or',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    // Manual inputs
                    TextField(
                      controller: _streetCtrl,
                      onChanged: (v) {
                        if (v.trim().isNotEmpty &&
                            _invalidFields.remove('street')) {
                          setState(() {
                            if (_invalidFields.isEmpty) _topErrorMsg = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Street Address *',
                        hintText: 'Street name, building number',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: _invalidFields.contains('street')
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: _invalidFields.contains('street')
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFF1565C0)),
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
                              border: const OutlineInputBorder(),
                              isDense: true,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: _invalidFields.contains('area')
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: _invalidFields.contains('area')
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFF1565C0)),
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
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: const Icon(Icons.search),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: _invalidFields.contains('city')
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: _invalidFields.contains('city')
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFF1565C0)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _landmarkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Landmark',
                        hintText: 'Nearby landmark (optional)',
                        border: OutlineInputBorder(),
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

              const SizedBox(height: 24),
              // ── Step 4: Description ──────────────────────────────────────────
              _sectionLabel('Step 4 • Description (Optional)'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _descriptionCtrl,
                  maxLines: 4,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  decoration: const InputDecoration(
                    hintText: 'Add a brief description (optional)...',
                    hintStyle:
                        TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              // ── Submit ───────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    disabledBackgroundColor:
                        const Color(0xFF1565C0).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    shadowColor: const Color(0xFF1565C0).withOpacity(0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Submit Report',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
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
    // If a video is present, show the video placeholder full-bleed
    if (_videoPath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: const Color(0xFF263238),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text('Video selected',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() {
                _videoPath = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('✓  Video added',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }

    // Otherwise show a 2x2 grid for up to 4 images sized to available space
    return LayoutBuilder(builder: (context, constraints) {
      // compute childAspectRatio so 2 rows fit into parent height
      // Account for GridView padding (8 each side) and the spacing between items (8)
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
              // pick images to fill remaining slots
              await _pickMultipleImages(closeModal: false);
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
                    Icon(Icons.add, size: 28, color: Color(0xFF1565C0)),
                    SizedBox(height: 6),
                    Text('Add',
                        style: TextStyle(
                            color: Color(0xFF1565C0),
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
            color: const Color(0xFF1565C0).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: Color(0xFF1565C0), size: 28),
        ),
        const SizedBox(height: 12),
        const Text('Add Photo / Video',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1565C0))),
        const SizedBox(height: 6),
        const Text('Tap to capture or upload from gallery',
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
                onTap: () => _pick(ImageSource.camera, false),
                child: _mediaBtn(Icons.camera_alt_outlined, 'Camera')),
            const SizedBox(width: 12),
            GestureDetector(
                onTap: () => _pick(ImageSource.camera, true),
                child: _mediaBtn(Icons.videocam_outlined, 'Video')),
          ],
        ),
      ],
    );
  }

  Widget _mediaBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF1565C0)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9E9E),
          letterSpacing: 0.5,
        ),
      );

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
