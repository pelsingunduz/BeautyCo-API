import 'package:flutter/material.dart';
import 'package:beautyco/services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.pink,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.pink),
            title: const Text('Çıkış Yap'),
            onTap: () async {
              await ApiService().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
} 