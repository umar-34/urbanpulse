import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dh51uajxy";
  static const String uploadPreset = "fyp_reports_preset";

  static Future<String?> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print("File does not exist at path: $filePath");
        return null;
      }

      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        return jsonMap['secure_url'] as String;
      } else {
        print('Cloudinary Upload Failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
