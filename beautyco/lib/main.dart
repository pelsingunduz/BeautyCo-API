import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_page.dart';
import 'screens/profile_screen.dart';
import 'package:beautyco/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:beautyco/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  await apiService.init(); // SharedPreferences'dan token yükleniyor

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beauty Co.',
      debugShowCheckedModeBanner: false,
      theme: beautyCoTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(apiService: apiService),
        '/register': (context) => RegisterScreen(apiService: apiService),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
