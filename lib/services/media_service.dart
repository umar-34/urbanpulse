import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MediaResult {
  final String path;
  final bool isVideo;

  const MediaResult({required this.path, required this.isVideo});
}

class MediaService {
  static final _picker = ImagePicker();

  /// Show a bottom-sheet style source picker and return the chosen media.
  static Future<MediaResult?> pickImage({required ImageSource source}) async {
    final xFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (xFile == null) return null;
    return MediaResult(path: xFile.path, isVideo: false);
  }

  static Future<List<MediaResult>?> pickImagesFromGallery() async {
    final files = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (files.isEmpty) return null;
    return files.map((f) => MediaResult(path: f.path, isVideo: false)).toList();
  }

  static Future<MediaResult?> pickVideo({required ImageSource source}) async {
    final xFile = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 2),
    );
    if (xFile == null) return null;
    return MediaResult(path: xFile.path, isVideo: true);
  }

  static File fileFrom(String path) => File(path);
}
