import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // ApiService import edildi

final Logger logger = Logger('LoginScreen');

class LoginScreen extends StatefulWidget {
  final ApiService apiService; // Eklendi

  const LoginScreen({Key? key, required this.apiService}) : super(key: key); // Parametre alması sağlandı

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _createAccount() {
    logger.info('Hesap oluşturma sayfasına gidiliyor');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterScreen(apiService: widget.apiService), // Parametre geçildi
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final url = Uri.parse('http://127.0.0.1:5000/login'); // IP'yi uygun şekilde güncelle

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await widget.apiService.init(); // ApiService'e token yeniden yükletiliyor

        logger.info('Giriş başarılı. Token kaydedildi: $token');

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final error = jsonDecode(response.body);
        logger.warning('Giriş başarısız: ${error['message']}');
        _showErrorDialog(error['message']);
      }
    } catch (e) {
      logger.severe('Giriş hatası: $e');
      _showErrorDialog('Bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.spa_outlined, size: 64, color: Colors.black87),
              const SizedBox(height: 16),
              Text('Beauty Co',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  )),
              const SizedBox(height: 8),
              Text('Hoş Geldiniz!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  )),
              const SizedBox(height: 40),
              _buildTextField(
                controller: _emailController,
                hintText: 'E-mail',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Şifremi unuttum işlemleri
                  },
                  child: Text('Şifremi Unuttum',
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 13,
                      )),
                ),
              ),
              const SizedBox(height: 10),
              _buildLoginButton(),
              const SizedBox(height: 16),
              _buildCreateAccountButton(),
              const SizedBox(height: 24),
              _buildTermsText(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Şifre',
        hintStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible
              ? Icons.visibility
              : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('Giriş Yap',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          )),
    );
  }

  Widget _buildCreateAccountButton() {
    return OutlinedButton(
      onPressed: _createAccount,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.black87),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text('Hesap Oluştur',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          )),
    );
  }

  Widget _buildTermsText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(
          color: Colors.black45,
          fontSize: 12,
        ),
        children: const [
          TextSpan(text: 'Hizmet şartlarınızı ve '),
          TextSpan(
            text: 'gizlilik politikanızı',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.black,
            ),
          ),
          TextSpan(text: ' kabul ediyorum.'),
        ],
      ),
    );
  }
}
