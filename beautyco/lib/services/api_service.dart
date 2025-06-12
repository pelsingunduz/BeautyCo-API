import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';

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
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };
  
  if (_authToken != null && _authToken!.isNotEmpty) {
    headers['x-access-token'] = _authToken!; // Flask often uses this
  }
  
  print('Request headers: $headers');
  print('Auth token: ${_authToken?.substring(0, 10)}...');
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
  try {
    print('Login attempt for email: $email');
    
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    print('Login response status: ${response.statusCode}');
    print('Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Token'ı class seviyesinde set et
      _authToken = data['token'];
      
      // SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('auth_token', data['token']);
      
      // ÖNEMLİ: User ID'yi de kaydet
      if (data['user'] != null && data['user']['id'] != null) {
        await prefs.setString('current_user_id', data['user']['id'].toString());
        print('User ID saved: ${data['user']['id']}');
      }
      
      _lastError = null;
      print('Login successful, token set: ${_authToken?.substring(0, 10)}...');
      return true;
      
    } else {
      final data = json.decode(response.body);
      _lastError = data['error'] ?? data['message'] ?? 'Giriş başarısız';
      print('Login failed: $_lastError');
      return false;
    }
  } catch (e) {
    _lastError = 'Sunucuya bağlanılamadı: $e';
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
// KULLANICILAR - DÜZELTME
// 3. API Service'e eklenecek düzeltilmiş getUserProfile metodu
// Updated getUserProfile method in ApiService
Future<User> getUserProfile(String userId) async {
  try {
    print('=== GET USER PROFILE DEBUG START ===');
    print('1. UserId: $userId');
    print('2. Token mevcut: ${_authToken != null}');
    print('3. Token değeri: ${_authToken?.substring(0, 10)}...');
    print('4. Base URL: $baseUrl');
    
    // Get current user ID to check if this is the current user's profile
    final currentUserId = await getCurrentUserId();
    print('5. Current User ID: $currentUserId');
    
    final url = Uri.parse('$baseUrl/users/$userId');
    print('6. Request URL: $url');
    
    final headers = _getHeaders();
    print('7. Request Headers: $headers');
    
    print('8. Making HTTP request...');
    final response = await http.get(url, headers: headers);
    
    print('9. Response Status: ${response.statusCode}');
    print('10. Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('11. Parsed user data: $data');
      
      Map<String, dynamic> userData;
      
      // Handle both array and object responses
      if (data is List && data.isNotEmpty) {
        userData = data[0];
      } else if (data is Map<String, dynamic>) {
        userData = data;
      } else {
        print('12. Unexpected data format: ${data.runtimeType}');
        throw Exception('Beklenmeyen veri formatı');
      }
      
      // Check if user is being followed (only if not current user's profile)
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != userId) {
        try {
          isFollowing = await checkIfFollowing(userId);
          print('13. Follow status: $isFollowing');
        } catch (e) {
          print('14. Follow status check failed: $e');
        }
      }
      
      userData['is_following'] = isFollowing;
      
      print('15. Returning User object...');
      return User.fromJson(userData);
      
    } else if (response.statusCode == 404) {
      print('12. User not found');
      throw Exception('Kullanıcı profili bulunamadı');
    } else if (response.statusCode == 401) {
      print('12. Authentication error');
      throw Exception('Yetkilendirme hatası');
    } else {
      print('12. Unexpected status code: ${response.statusCode}');
      throw Exception('Profile loading failed: ${response.statusCode}');
    }
  } catch (e) {
    print('=== GET USER PROFILE ERROR ===');
    print('Error: $e');
    print('Error type: ${e.runtimeType}');
    print('Stack trace: ${StackTrace.current}');
    
    if (e.toString().contains('FormatException')) {
      throw Exception('Geçersiz JSON formatı');
    }
    throw Exception('Network error: $e');
  } finally {
    print('=== GET USER PROFILE DEBUG END ===');
  }
}

// Add this helper method to check if current user is following another user
Future<bool> checkIfFollowing(String userId) async {
  try {
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) return false;
    
    final following = await getFollowing(currentUserId);
    
    // Check if the userId exists in the following list
    return following.any((user) => user['id'].toString() == userId);
    
  } catch (e) {
    print('checkIfFollowing error: $e');
    return false;
  }
}
// 4. Eksik olan kullanıcı incelemelerini getirme metodu
Future<List<dynamic>> getUserReviews(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/user-reviews/$userId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      _lastError = 'Kimlik doğrulama gerekli.';
      throw Exception('Authentication required.');
    } else {
      _lastError = 'Kullanıcı incelemeleri yüklenirken hata oluştu.';
      throw Exception('Failed to load user reviews.');
    }
  } catch (e) {
    _lastError = 'Kullanıcı incelemeleri yüklenirken hata oluştu: $e';
    throw Exception(_lastError);
  }
}

// 5. Profil güncelleme metodu
Future<Map<String, dynamic>> updateUserProfile({
  required String userId,
  String? name,
  String? email,
  String? profilePhoto,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _getHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (profilePhoto != null) 'profile_photo': profilePhoto,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'data': responseData};
    } else {
      _lastError = responseData['error'] ?? 'Profil güncellenirken hata oluştu.';
      return {'success': false, 'message': _lastError};
    }
  } catch (e) {
    _lastError = 'Profil güncellenirken hata oluştu: $e';
    return {'success': false, 'message': _lastError};
  }
}

// 7. Debug için API durumunu kontrol etme metodu
Future<Map<String, dynamic>> getApiStatus() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/status'),
      headers: {'Content-Type': 'application/json'},
    );
    
    return {
      'status_code': response.statusCode,
      'body': response.body,
      'success': response.statusCode == 200,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
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
  // KULLANICI TAKİP ET
  Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/follow'),
        headers: _getHeaders(),
        body: jsonEncode({'user_id': userId}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        _lastError = responseData['error'] ?? 'Kullanıcı takip edilirken hata oluştu.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'Kullanıcı takip edilirken hata oluştu: $e';
      return {'success': false, 'message': _lastError};
    }
  }

  // KULLANICI TAKİPTEN ÇIK
  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/follow/$userId'),
        headers: _getHeaders(),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        _lastError = responseData['error'] ?? 'Kullanıcı takipten çıkarılırken hata oluştu.';
        return {'success': false, 'message': _lastError};
      }
    } catch (e) {
      _lastError = 'Kullanıcı takipten çıkarılırken hata oluştu: $e';
      return {'success': false, 'message': _lastError};
    }
  }

  // TAKİPÇİLERİ GETİR
  Future<List<dynamic>> getFollowers(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/followers/$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Takipçiler yüklenirken hata oluştu.';
        throw Exception('Failed to load followers.');
      }
    } catch (e) {
      _lastError = 'Takipçiler yüklenirken hata oluştu: $e';
      throw Exception(_lastError);
    }
  }

  // TAKİP EDİLENLERİ GETİR
  Future<List<dynamic>> getFollowing(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/following/$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Takip edilenler yüklenirken hata oluştu.';
        throw Exception('Failed to load following.');
      }
    } catch (e) {
      _lastError = 'Takip edilenler yüklenirken hata oluştu: $e';
      throw Exception(_lastError);
    }
  }
Future<String?> getCurrentUserId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      debugPrint('❌ No auth token found');
      return null;
    }
    
    // Token'dan user_id'sini çıkar
    final parts = token.split('.');
    if (parts.length != 3) {
      debugPrint('❌ Invalid token format');
      return null;
    }
    
    // JWT payload'ı decode et
    final payload = parts[1];
    final normalizedPayload = base64Url.normalize(payload);
    final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
    final payloadMap = json.decode(decodedPayload);
    
    final userId = payloadMap['user_id']?.toString();
    debugPrint('🔍 Token decoded user_id: $userId');
    return userId;
    
  } catch (e) {
    debugPrint('❌ Error decoding token: $e');
    return null;
  }
}

  // CURRENT USER ID'Yİ KAYDETME METODU (Login sonrasında kullanılacak)
  Future<void> saveCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
    } catch (e) {
      print('Current user ID kaydedilirken hata: $e');
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

  Future<Map<String, dynamic>> removeFavorite(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$productId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['error'] ?? 'Favori kaldırma işlemi başarısız.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Hata: $e'};
    }
  } 
  // ÜRÜNLER - GET PRODUCTS METHOD
Future<List<dynamic>> getProducts() async {
  try {
    print('getProducts çağrılıyor...');
    print('Token mevcut: ${_authToken != null}');
    
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _getHeaders(),
    );

    print('getProducts response status: ${response.statusCode}');
    print('getProducts response body: ${response.body}');

    if (response.statusCode == 200) {
      _lastError = null;
      final data = json.decode(response.body);
      
      if (data is List) {
        print('${data.length} ürün bulundu');
        return data;
      } else {
        print('Beklenmeyen veri formatı: ${data.runtimeType}');
        return [];
      }
    } else if (response.statusCode == 401) {
      _lastError = 'Kimlik doğrulama gerekli.';
      throw Exception('Authentication required.');
    } else {
      _lastError = 'Ürünleri yüklerken hata oluştu. Status: ${response.statusCode}';
      throw Exception('Failed to load products. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('getProducts error: $e');
    _lastError = 'Ürünleri yüklerken hata oluştu: $e';
    throw Exception(_lastError);
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

  // Ana Sayfa Akışı için İncelemeleri Getir
  Future<List<dynamic>> getFeedPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feed'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        _lastError = 'Kimlik doğrulama gerekli.';
        throw Exception('Authentication required.');
      } else {
        _lastError = 'Akış gönderileri yüklenirken hata oluştu.';
        throw Exception('Failed to load feed posts.');
      }
    } catch (e) {
      _lastError = 'Akış gönderileri yüklenirken hata oluştu: $e';
      throw Exception(_lastError);
    }
  }

  Future<Map<String, dynamic>> updateProfile(String userId, String name, String? profilePhoto) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': await _getToken(),
        },
        body: jsonEncode({
          'name': name,
          'profile_photo': profilePhoto,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Profil güncellenirken bir hata oluştu');
      }
    } catch (e) {
      throw Exception('Profil güncellenirken bir hata oluştu: $e');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }
}