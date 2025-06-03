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
  Future<bool> register(String name, String email, String password, {String? profilePhoto}) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
      };
      
      if (profilePhoto != null) {
        body['profile_photo'] = profilePhoto;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        _lastError = null;
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

  // KULLANICILAR - MISSING METHOD
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Kullanıcıları yüklerken hata oluştu.';
        throw Exception('Failed to load users.');
      }
    } catch (e) {
      _lastError = 'Kullanıcıları yüklerken hata oluştu: $e';
      throw Exception(_lastError);
    }
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

  // ÜRÜN DETAYI - MISSING METHOD
  Future<Map<String, dynamic>?> getProductDetail(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product/$productId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        _lastError = 'Ürün bulunamadı.';
        return null;
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Ürün detayı yüklenirken hata oluştu.';
        throw Exception('Failed to load product detail.');
      }
    } catch (e) {
      _lastError = 'Ürün detayı yüklenirken hata oluştu: $e';
      throw Exception(_lastError);
    }
  }

  // ÜRÜN EKLE - MISSING METHOD
  Future<Map<String, dynamic>> addProduct({
    required String name,
    String? brand,
    int? categoryId,
    String? description,
    double? averageRating,
    String? productPhoto,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/product'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'brand': brand,
          'category_id': categoryId,
          'description': description,
          'average_rating': averageRating,
          'product_photo': productPhoto,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        _lastError = responseData['error'] ?? 'Ürün eklenirken hata oluştu.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'Ürün eklenirken hata oluştu: $e';
      return {'success': false, 'message': _lastError};
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

  // KATEGORİ EKLE - MISSING METHOD
  Future<Map<String, dynamic>> addCategory(String categoryName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/category'),
        headers: _getHeaders(),
        body: jsonEncode({'category_name': categoryName}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        _lastError = responseData['error'] ?? 'Kategori eklenirken hata oluştu.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'Kategori eklenirken hata oluştu: $e';
      return {'success': false, 'message': _lastError};
    }
  }

  // FAVORİLER - MISSING METHOD
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Favorileri yüklerken hata oluştu.';
        throw Exception('Failed to load favorites.');
      }
    } catch (e) {
      _lastError = 'Favorileri yüklerken hata oluştu: $e';
      throw Exception(_lastError);
    }
  }

  // FAVORİ EKLE - MISSING METHOD
  Future<Map<String, dynamic>> addFavorite(int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorite'),
        headers: _getHeaders(),
        body: jsonEncode({'product_id': productId}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        _lastError = responseData['error'] ?? 'Favori eklenirken hata oluştu.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'Favori eklenirken hata oluştu: $e';
      return {'success': false, 'message': _lastError};
    }
  }

  // İNCELEMELER - MISSING METHOD
  Future<List<dynamic>> getProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/$productId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'İncelemeleri yüklerken hata oluştu.';
        throw Exception('Failed to load reviews.');
      }
    } catch (e) {
      _lastError = 'İncelemeleri yüklerken hata oluştu: $e';
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
        _lastError = responseData['error'] ?? responseData['message'] ?? 'İnceleme eklenirken hata oluştu.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'İnceleme eklenirken hata oluştu: $e';
      return {'success': false, 'message': _lastError};
    }
  }

 Future<List<dynamic>> searchProducts(String query) async {
  try {
    print('=== SEARCH DEBUG START ===');
    print('1. Query: "$query"');
    print('2. Query length: ${query.length}');
    print('3. Base URL: $baseUrl');
    print('4. Auth Token exists: ${_authToken != null}');
    print('5. Auth Token value: ${_authToken?.substring(0, 10)}...');
    
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('$baseUrl/search?q=$encodedQuery');
    print('6. Encoded query: "$encodedQuery"');
    print('7. Full URL: $url');
    
    final headers = _getHeaders();
    print('8. Headers: $headers');
    
    print('9. Making HTTP request...');
    final response = await http.get(url, headers: headers);
    
    print('10. Response received!');
    print('11. Status Code: ${response.statusCode}');
    print('12. Response Headers: ${response.headers}');
    print('13. Response Body: ${response.body}');
    print('14. Response Body Type: ${response.body.runtimeType}');
    print('15. Response Body Length: ${response.body.length}');

    if (response.statusCode == 200) {
      print('16. Status 200 - Success');
      _lastError = null;
      
      if (response.body.isEmpty) {
        print('17. Response body is empty!');
        return [];
      }
      
      try {
        print('18. Attempting to decode JSON...');
        final data = json.decode(response.body);
        print('19. JSON decoded successfully');
        print('20. Decoded data type: ${data.runtimeType}');
        
        if (data is List) {
          print('21. Data is List with ${data.length} items');
          if (data.isNotEmpty) {
            print('22. First item: ${data.first}');
            print('23. First item type: ${data.first.runtimeType}');
          }
          return data;
        } else {
          print('21. Data is NOT a List: $data');
          return [];
        }
      } catch (jsonError) {
        print('18. JSON decode error: $jsonError');
        print('19. Raw response: "${response.body}"');
        throw Exception('JSON decode error: $jsonError');
      }
      
    } else if (response.statusCode == 401) {
      print('16. Status 401 - Authentication required');
      _lastError = 'Kimlik doğrulama gerekli.';
      throw Exception('Authentication required.');
    } else {
      print('16. Status ${response.statusCode} - Error');
      print('17. Error response body: ${response.body}');
      _lastError = 'Arama sırasında hata oluştu. Status: ${response.statusCode}';
      throw Exception('Failed to search products. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('=== SEARCH ERROR ===');
    print('Error: $e');
    print('Error type: ${e.runtimeType}');
    print('Stack trace: ${StackTrace.current}');
    
    _lastError = 'Arama sırasında hata oluştu: $e';
    rethrow; // UI'da yakalanabilmesi için
  } finally {
    print('=== SEARCH DEBUG END ===');
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

  // TEST VERİTABANI BAĞLANTISI - MISSING METHOD
  Future<Map<String, dynamic>> testDatabaseConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        _lastError = responseData['error'] ?? 'Veritabanı bağlantı testi başarısız.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'Veritabanı bağlantı testi sırasında hata: $e';
      return {'success': false, 'message': _lastError};
    }
  }

  // Hata mesajını temizle
  static void clearError() {
    _lastError = null;
  }
}