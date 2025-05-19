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
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'ayse_96',
      'product': 'Glowy Foundation',
      'content': 'Harika bir kapatıcılığı var, cildimde çok doğal durdu!',
      'category': 'Makyaj',
      'showCommentField': false,
      'comments': [],
    },
    {
      'username': 'melisbeauty',
      'product': 'Vitamin C Serum',
      'content': 'Cildim çok daha aydınlık oldu, öneririm.',
      'category': 'Cilt Bakımı',
      'showCommentField': false,
      'comments': [],
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
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );

      if (result != null && result is Map) {
        setState(() {
          _posts.insert(0, {
            'username': 'sen', // Kullanıcı adını dinamik yapabilirsin
            'product': result['product'] ?? '',
            'content': result['review'] ?? '',
            'category': result['category'] ?? 'Makyaj',
            'showCommentField': false,
            'rating': result['rating'] ?? 0,
            'brand': result['brand'] ?? '',
            'productPhoto': result['productPhoto'] ?? '',
            'comments': [],
          });
          _selectedIndex = 0;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['username'],
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${post['brand'] ?? ''} - ${post['product']}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (post['rating'] != null && post['rating'] > 0)
                  Row(
                    children: [
                      Icon(Icons.star, color: primaryRed, size: 16),
                      Text(
                        ' ${post['rating']}',
                        style: GoogleFonts.montserrat(
                          color: primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (post['productPhoto'] != null && post['productPhoto'].isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(post['productPhoto']),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
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
                      if (!post['showCommentField']) {
                        _commentController.clear();
                      }
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
              Column(
                children: [
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Yorumunuzu yazın...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(8),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: primaryRed),
                        onPressed: () {
                          if (_commentController.text.trim().isNotEmpty) {
                            setState(() {
                              // Yeni yorumu ekle
                              if (!_posts[index].containsKey('comments')) {
                                _posts[index]['comments'] = [];
                              }
                              _posts[index]['comments'].add({
                                'username': 'sen', // Kullanıcı adını dinamik yapabilirsin
                                'content': _commentController.text.trim(),
                                'timestamp': DateTime.now().toString(),
                              });
                              _commentController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (post['comments'] != null && post['comments'].isNotEmpty)
                    Column(
                      children: [
                        const Divider(),
                        ...post['comments'].map<Widget>((comment) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 12,
                                child: Icon(Icons.person, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment['username'],
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      comment['content'],
                                      style: GoogleFonts.montserrat(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                ],
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