import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:beautyco/screens/profile_screen.dart';
import 'package:beautyco/screens/create_post.dart';
import 'package:beautyco/screens/search_screen.dart';
import 'package:beautyco/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'TÜM';

  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'ayse_96',
      'product': 'Glowy Foundation',
      'content': 'Harika bir kapatıcılığı var, cildimde çok doğal durdu!',
      'category': 'Makyaj',
      'showCommentField': false,
    },
    {
      'username': 'melisbeauty',
      'product': 'Vitamin C Serum',
      'content': 'Cildim çok daha aydınlık oldu, öneririm.',
      'category': 'Cilt Bakımı',
      'showCommentField': false,
    },
  ];

  final List<String> _categories = [
    'TÜM',
    'Makyaj',
    'Cilt Bakımı',
    'Saç',
    'Parfüm',
    'Kişisel Bakım',
  ];

  void _onItemTapped(int index) async {
    if (index == 1) {
      // CreatePostScreen'den veri bekle
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );

      // Check if result has the category field and handle if it's a map
      if (result != null && result is Map) {
        setState(() {
          _posts.insert(0, {
            'username': 'sen', // Kullanıcı adını dinamik yapabilirsin
            'product': result['product'] ?? '',
            'content': result['review'] ?? '',
            'category': result['category'] ?? 'Makyaj', // Use the selected category
            'showCommentField': false,
          });
          _selectedIndex = 0; // Ana sayfaya geri dön
          
          // Optional: Auto-select the category tab after posting
          _selectedCategory = result['category'] ?? 'Makyaj';
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildCategoryButton(String title) {
    final bool isSelected = _selectedCategory == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryRed : roseGold, width: 1),
        ),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            color: isSelected ? Colors.white : primaryRed,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${post['username']} - ${post['product']}',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.photo, size: 50, color: Colors.grey)),
            ),
            const SizedBox(height: 10),
            Text(
              post['content'],
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kategori: ${post['category']}',
                  style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 12),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _posts[index]['showCommentField'] = !post['showCommentField'];
                    });
                  },
                  child: Text(
                    post['showCommentField'] ? 'Yorumu Kapat' : 'Yorum Yap',
                    style: const TextStyle(color: primaryRed),
                  ),
                ),
              ],
            ),
            if (post['showCommentField'])
              TextField(
                decoration: InputDecoration(
                  hintText: 'Yorumunuzu yazın...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _selectedCategory == 'TÜM'
        ? _posts
        : _posts.where((post) => post['category'] == _selectedCategory).toList();

    final List<Widget> _screens = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) =>
                  _buildCategoryButton(_categories[index]),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) =>
                  _buildPostCard(filteredPosts[index], index),
            ),
          ),
        ],
      ),
      Container(), // Paylaş sekmesi artık burada değil
      const SearchScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryRed,
        title: Text(
          'BeautyCo',
          style: GoogleFonts.pacifico(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryRed,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Paylaş'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Ara'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}