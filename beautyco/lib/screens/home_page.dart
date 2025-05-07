import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'profile_screen.dart'; // ProfileScreen sınıfı için import eklendi
import 'package:beautyco/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import './create_post.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beauty Co.',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedPostCategory = 'tüm incelemeler';

  // Yorum metni için controller
  final TextEditingController _commentController = TextEditingController();

  // Post listesi için yeni bir değişken ekleyelim
  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'jess_tk',
      'skinType': 'Hassas cilt, akneli, karma cilt',
      'brand': 'MAYBELLINE',
      'productName': 'Maybelline Lash Sensational Sky High Mascara',
      'rating': 4.3,
      'reviewCount': '1764 reviews',
      'postTitle': 'Kahverengi değil mi?',
      'postContent': 'Bu maskara kahverengi değil mi? Benim için çok açık kalıyor. Başka birisi de aynı sorunu yaşadı mı?',
      'comments': 1,
      'showCommentField': true,
    },
    {
      'username': 'beauty.emma',
      'skinType': 'Normal cilt, kuru cilt',
      'brand': 'CERAVE',
      'productName': 'CeraVe Moisturizing Cream',
      'rating': 4.8,
      'reviewCount': '2453 reviews',
      'postTitle': 'Bu kremi denedim!',
      'postContent': 'Bu kremi denedim ve gerçekten çok beğendim! Cildim çok kuru olduğu için nemlendirici arıyordum. Bu krem tam istediğim gibi!',
      'comments': 4,
      'showCommentField': false,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Bottom navigation için yeni onTap fonksiyonu
  void _onItemTapped(int index) async {
    if (index == 2) {
      // Arama sayfasına git
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      );
    } else if (index == 1) {
      // Create Post sayfasına git
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );
      
      if (result != null) {
        // Yeni postu listeye ekle
        setState(() {
          _posts.insert(0, {
            'username': 'fsude',
            'skinType': 'Normal cilt',
            'brand': result['product'].split(' ')[0],
            'productName': result['product'],
            'rating': result['rating'].toDouble(),
            'reviewCount': '1 review',
            'postTitle': result['title'],
            'postContent': result['review'],
            'comments': 0,
            'showCommentField': false,
          });
        });
      }
    } else if (index == 0) {
      // Ana sayfada kalın veya yeniden yükleyin
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 3) {
      // Profil sayfasına git
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: champagneGold,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [champagneGold, Colors.white],
              stops: [0.0, 0.7],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst bilgi çubuğu (siyah alan)
              Container(
                color: primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hoşgeldiniz!',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Ana app bar
              AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                toolbarHeight: 60,
                leading: const IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryRed),
                  onPressed: null,
                ),
                title: Row(
                  children: [
                    Text(
                      'BeautyCo',
                      style: GoogleFonts.montserrat(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: primaryRed),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: primaryRed),
                    onPressed: () {},
                  ),
                ],
              ),
              // Kategori Menüsü
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _buildCategoryButton('TÜM', isSelected: true),
                    _buildCategoryButton('Cilt Bakımı', isSelected: false),
                    _buildCategoryButton('Saç', isSelected: false),
                    _buildCategoryButton('Makyaj', isSelected: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Son gönderileri keşfet.',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İncelemelerini paylaş ve başkalarının incelemelerini keşfet.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: darkRed,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Kategori butonları burada
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Post listesi
            Expanded(
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: _buildPostCard(
                      username: post['username'],
                      skinType: post['skinType'],
                      brand: post['brand'],
                      productName: post['productName'],
                      rating: post['rating'],
                      reviewCount: post['reviewCount'],
                      postTitle: post['postTitle'],
                      postContent: post['postContent'],
                      comments: post['comments'],
                      showCommentField: post['showCommentField'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryRed,
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Create Post'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'fsude'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? primaryRed : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? primaryRed : roseGold, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildPostCategoryButton(String title, {required bool isSelected}) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPostCategory = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required String username,
    required String skinType,
    required String brand,
    required String productName,
    required double rating,
    required String reviewCount,
    required String postTitle,
    required String postContent,
    required int comments,
    required bool showCommentField,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: darkRed.withOpacity(0.07),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: roseGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: primaryRed,
                  radius: 20,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryRed,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: roseGold),
              ],
            ),
          ),
          // User skin info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cilt Tipi',
                        style: GoogleFonts.poppins(
                          color: roseGold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        skinType,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darkRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Product review card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: roseGold.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
                color: lightRed.withOpacity(0.3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Product image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: roseGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.photo, color: roseGold, size: 36),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: darkRed,
                            ),
                          ),
                          Text(
                            productName,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryRed,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                rating.toString(),
                                style: GoogleFonts.montserrat(
                                  color: primaryRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              ...List.generate(5, (i) => Icon(
                                i < rating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                                color: primaryRed,
                                size: 18,
                              )),
                              const SizedBox(width: 8),
                              Text(
                                reviewCount,
                                style: GoogleFonts.poppins(
                                  color: darkRed,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Post content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  postTitle,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: darkRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  postContent,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Interaction buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.favorite_border, color: primaryRed),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: darkRed),
                    const SizedBox(width: 4),
                    Text('$comments', style: GoogleFonts.poppins(color: darkRed)),
                  ],
                ),
                Icon(Icons.share_outlined, color: roseGold),
                Icon(Icons.bookmark_border, color: roseGold),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (showCommentField)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: roseGold.withOpacity(0.5), width: 1),
                  ),
                ),
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: darkRed,
                      radius: 16,
                      child: Text(
                        'S',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '1 saat önce',
                          style: GoogleFonts.poppins(
                            color: darkRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}