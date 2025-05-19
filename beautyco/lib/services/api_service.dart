import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';
  static String? _authToken;
  static String? _lastError;

  // ✅ Error getter
  static String? get lastError => _lastError;

  // ✅ isLoggedIn getter
  static bool get isLoggedIn => _authToken != null;

  // ✅ Token getter
  static String? get token => _authToken;

  // ✅ init method
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    print('Auth token loaded: ${_authToken != null ? 'Token mevcut' : 'Token yok'}');
  }

  // Header getter
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_authToken != null) {
      headers['x-access-token'] = _authToken!;
    }
    return headers;
  }

  // REGISTER
  Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        _lastError = data['error'] ?? data['message'] ?? 'Bilinmeyen hata';
        return false;
      }
    } catch (e) {
      _lastError = 'Sunucuya bağlanılamadı: $e';
      print('Register error: $e');
      return false;
    }
  }

  // LOGIN
  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);

        _lastError = null;
        return true;
      } else {
        final data = jsonDecode(response.body);
        _lastError = data['message'] ?? 'Giriş başarısız';
        return false;
      }
    } catch (e) {
      _lastError = 'Giriş işlemi sırasında hata: $e';
      print('Login error: $e');
      return false;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('Logged out');
  }

  // ÜRÜNLER
  Future<List<dynamic>> getProducts() async {
    try {
      print('Getting products with token: ${_authToken != null ? 'mevcut' : 'yok'}');
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _getHeaders(),
      );
      print('Products response status: ${response.statusCode}');
      print('Products response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Ürünleri yüklerken hata oluştu.';
        throw Exception('Failed to load products.');
      }
    } catch (e) {
      _lastError = 'Ürünleri yüklerken hata oluştu: $e';
      throw Exception(_lastError);
    }
  }

  // KATEGORİLER
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Kategorileri yüklerken hata oluştu.';
        throw Exception('Failed to load categories.');
      }
    } catch (e) {
      _lastError = 'Kategorileri yüklerken hata oluştu: $e';
      throw Exception(_lastError);
    }
  }

  // İNCELEME EKLE
  Future<Map<String, dynamic>> addReview(int productId, String reviewText, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review'),
        headers: _getHeaders(),
        body: jsonEncode({
          'product_id': productId,
          'review_text': reviewText,
          'rating': rating,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        _lastError = responseData['message'] ?? 'İnceleme eklenirken hata oluştu.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'İnceleme eklenirken hata oluştu: $e';
      return {'success': false, 'message': _lastError};
    }
  }

  // TEST BAĞLANTI
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
