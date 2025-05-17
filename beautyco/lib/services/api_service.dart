import 'dart:convert'; 
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart';  

class ApiService {
  final String baseUrl = 'http://127.0.0.1:5000'; // API adresi
  String? _authToken;
  String? lastError; // Hata mesajlarını saklamak için eklendi
  
  // Uygulama başında token yükleme
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    print('Auth token loaded: ${_authToken != null ? 'Token mevcut' : 'Token yok'}');
  }
  
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
  
  // Kullanıcı kaydı için eklenen method
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Registration successful');
        return true;
      } else {
        lastError = 'Kayıt başarısız: ${response.body}';
        print(lastError);
        return false;
      }
    } catch (e) {
      lastError = 'Kayıt hatası: $e';
      print(lastError);
      return false;
    }
  }
  
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _authToken = data['token'] ?? data['access_token'];
        if (_authToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _authToken!);
          print('Token saved successfully');
          return true;
        }
      }
      lastError = 'Giriş başarısız: ${response.body}';
      return false;
    } catch (e) {
      lastError = 'Giriş hatası: $e';
      print('Login error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('Logged out');
  }
  
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        lastError = 'Kimlik doğrulama gerekli. Lütfen giriş yapın.';
        throw Exception('Authentication required. Please login.');
      } else {
        lastError = 'Ürünleri yüklerken hata oluştu: ${response.body}';
        throw Exception('Failed to load products');
      }
    } catch (e) {
      lastError = 'Ürünleri yüklerken hata oluştu: $e';
      throw Exception('Failed to load products: $e');
    }
  }
  
  // Kategorileri getiren method
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        lastError = 'Kimlik doğrulama gerekli. Lütfen giriş yapın.';
        throw Exception('Authentication required. Please login.');
      } else {
        lastError = 'Kategorileri yüklerken hata oluştu: ${response.body}';
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      lastError = 'Kategorileri yüklerken hata oluştu: $e';
      throw Exception('Failed to load categories: $e');
    }
  }
  
  // Ürün değerlendirmesi/incelemesi ekleyen method
  Future<Map<String, dynamic>> addReview(
    int productId,
    String reviewText,
    int rating,
  ) async {
    try {
      final Map<String, dynamic> reviewData = {
        'product_id': productId,
        'review_text': reviewText,
        'rating': rating,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: _getHeaders(),
        body: jsonEncode(reviewData),
      );
      
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Review added successfully');
        return {'success': true, 'data': responseData};
      } else {
        lastError = 'İnceleme eklenirken hata oluştu: ${response.body}';
        print(lastError);
        return {
          'success': false, 
          'message': responseData['message'] ?? lastError
        };
      }
    } catch (e) {
      lastError = 'İnceleme eklenirken hata oluştu: $e';
      print(lastError);
      return {'success': false, 'message': lastError};
    }
  }
}