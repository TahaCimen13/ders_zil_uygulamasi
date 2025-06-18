// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5001/api";

  static Future<List<Map<String, dynamic>>> getTimes() async {
    final response = await http.get(Uri.parse('$baseUrl/times'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data.entries.map((e) => {'day': e.key, 'times': e.value}).toList();
    } else {
      throw Exception('Zamanlar alınamadı');
    }
  }

  static Future<void> addTime(String day, String time, String sound) async {
    final response = await http.post(
      Uri.parse('$baseUrl/times'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'day': day, 'time': time, 'sound': sound}),
    );
    if (response.statusCode != 200) {
      throw Exception('Saat eklenemedi');
    }
  }

  static Future<List<String>> getSounds() async {
    final response = await http.get(Uri.parse('$baseUrl/sounds'));
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Sesler alınamadı');
    }
  }

  static Future<void> deleteTime(String day, String time) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/times'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'day': day, 'time': time}),
    );
    if (response.statusCode != 200) {
      throw Exception('Saat silinemedi');
    }
  }

  static Future<void> testBell() async {
    final response = await http.get(Uri.parse('$baseUrl/test-bell'));
    if (response.statusCode != 200) {
      throw Exception('Zil çalınamadı');
    }
  }

  static Future<String> uploadSound(String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();

    final resBody = await http.Response.fromStream(response);

    if (resBody.statusCode == 200) {
      final decoded = json.decode(resBody.body);
      return decoded['filename'];
    } else {
      throw Exception('Ses yüklenemedi');
    }
  }

  static Future<void> updateTime({
    required String oldDay,
    required String oldTime,
    required String newDay,
    required String newTime,
    required String newSound,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-time'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'old_day': oldDay,
        'old_time': oldTime,
        'new_day': newDay,
        'new_time': newTime,
        'new_sound': newSound,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Güncelleme başarısız');
    }
  }
}
