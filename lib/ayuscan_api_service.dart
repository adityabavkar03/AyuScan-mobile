import 'dart:convert';
import 'package:http/http.dart' as http;

class AyuScanApiService {
  // ✅ Android emulator uses 10.0.2.2 to reach your PC's localhost
  static const String _baseUrl = 'http://172.16.252.232:5000';

  /// Predict Dosha from pulse + user details
  static Future<Map<String, dynamic>> predictDosha({
    required String uid,
    required double bpm,
    required int pulseRhythm,
    required int pulseStrength,
    required int pulseSpeed,
    required int skinType,
    required double bodyTemp,
    required int sleepQuality,
    required int digestion,
    required int stressLevel,
    required int age,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'bpm': bpm,
          'pulse_rhythm': pulseRhythm,
          'pulse_strength': pulseStrength,
          'pulse_speed': pulseSpeed,
          'skin_type': skinType,
          'body_temp': bodyTemp,
          'sleep_quality': sleepQuality,
          'digestion': digestion,
          'stress_level': stressLevel,
          'age': age,
          'save_result': true,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': 'Server error ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to server. Is it running?'};
    }
  }

  /// Get Dosha recommendations
  static Future<Map<String, dynamic>> getRecommendations(String dosha) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/recommendations?dosha=$dosha&type=summary'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user scan history
  static Future<List<dynamic>> getScanHistory(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/scan/history/$uid?limit=10'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['scans'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Check if backend is online
  static Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
