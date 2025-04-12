import 'package:flutter/material.dart'; 
import 'screens/login_screen.dart'; // LoginScreen dosyasını doğru içe aktardığınızdan emin olun

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeautyCo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      // Burada, ilk açılış ekranını LoginScreen yapıyoruz
      home: const LoginScreen(),  // LoginScreen başlangıç ekranı olarak ayarlandı
    );
  }
}
