import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenShotService {
  static const String baseUrl = 'YOUR_EC2_INSTANCE_URL';
  static const int timeoutDuration = 10; // seconds

  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: timeoutDuration));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String> uploadVideoForEditing(File video) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('video', video.path));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to upload video: ${jsonResponse['message']}');
      }
      
      return jsonResponse['projectId'];
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<Map<String, dynamic>> getEditingStatus(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status/$projectId'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get status');
      }
      
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to get editing status: $e');
    }
  }

  Future<String> downloadProcessedVideo(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/download/$projectId'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download processed video');
      }
      
      // Save to temporary file and return path
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/processed_$projectId.mp4');
      await tempFile.writeAsBytes(response.bodyBytes);
      
      return tempFile.path;
    } catch (e) {
      throw Exception('Failed to download processed video: $e');
    }
  }
} 