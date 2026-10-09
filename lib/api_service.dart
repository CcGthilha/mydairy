import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'main.dart';

// ==========================================
// 2. ApiService (Lab 2: timeout + try-catch)
// ==========================================
class ApiService {
  ApiService._();

  // ดึงคำคมแบบสุ่มจาก DummyJSON (มี timeout 10 วินาที และ try-catch กันค้าง)
  static Future<Quote> fetchQuote() async {
    try {
      final url = Uri.parse('https://dummyjson.com/quotes/random');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Quote.fromJson(data);
      } else {
        throw Exception('เซิร์ฟเวอร์ตอบผิดพลาด (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('เชื่อมต่อไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต');
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา (Timeout) กรุณาลองใหม่');
    } catch (e) {
      throw Exception('เชื่อมต่อไม่ได้ ตรวจสอบอินเทอร์เน็ต');
    }
  }

  // ดึงคำคมสำหรับหน้าเกี่ยวกับ (โบนัส API หน้าที่สอง)
  static Future<String> fetchDailyInspiration() async {
    try {
      final quote = await fetchQuote();
      return '"${quote.quote}"\n— ${quote.author}';
    } catch (_) {
      return '"ทุกวันคือโอกาสในการเริ่มต้นสิ่งใหม่ๆ"';
    }
  }

  // ---------- REST API CRUD (สัปดาห์ 4) ----------
  static const String studentId = '67011212113';
  static const String baseUrl = 'https://thipwimon.comsciproject.net/mydiary/api.php/$studentId';
  static const _h = {'Content-Type': 'application/json'};

  static Map<String, String> _body(String t, String c, String m, String d) => {'title': t, 'content': c, 'mood': m, 'date': d};

  // CREATE (POST)
  static Future<void> createDiary(String title, String content, String mood, String date) async {
    final r = await http.post(Uri.parse(baseUrl), headers: _h, body: jsonEncode(_body(title, content, mood, date)));
    if (r.statusCode != 200 && r.statusCode != 201) throw Exception('เพิ่มไม่สำเร็จ (${r.statusCode})');
  }

  // READ (GET)
  static Future<List<dynamic>> getDiaries() async {
    final r = await http.get(Uri.parse(baseUrl));
    if (r.statusCode != 200) throw Exception('โหลดไม่สำเร็จ (${r.statusCode})');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  // UPDATE (PUT)
  static Future<void> updateDiary(dynamic id, String title, String content, String mood, String date) async {
    final r = await http.put(Uri.parse('$baseUrl/$id'), headers: _h, body: jsonEncode(_body(title, content, mood, date)));
    if (r.statusCode != 200) throw Exception('แก้ไขไม่สำเร็จ (${r.statusCode})');
  }

  // DELETE
  static Future<void> deleteDiary(dynamic id) async {
    final r = await http.delete(Uri.parse('$baseUrl/$id'));
    if (r.statusCode != 200) throw Exception('ลบไม่สำเร็จ (${r.statusCode})');
  }
}