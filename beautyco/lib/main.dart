import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_page.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart'; // SearchScreen import'u eklendi
import 'screens/create_post.dart';    // CreatePostScreen import'u eklendi
import 'screens/product_detail_screen.dart'; // ProductDetailScreen import'u eklendi
import 'package:beautyco/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:beautyco/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ApiService.init();
  
  final apiService = ApiService();
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
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/search': (context) => const SearchScreen(),
        '/create-post': (context) => const CreatePostScreen(),
      },
      // Route'lar arası veri geçişi için onGenerateRoute kullanabilirsiniz
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/product-detail':
            // ProductDetailScreen için parametre geçişi
            if (settings.arguments != null) {
              return MaterialPageRoute(
                builder: (context) => settings.arguments as Widget,
              );
            }
            break;
        }
        return null;
      },
    );
  }
}