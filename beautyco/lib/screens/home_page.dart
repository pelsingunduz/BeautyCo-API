import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            // Üst bilgi çubuğu (siyah alan)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hoşgeldiniz!',
                      style: TextStyle(color: Colors.white, fontSize: 13),
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
              leading: const IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: null,
              ),
              title: Row(
                children: [
                  Text(
                    'BeautyCo',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Times New Roman',
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '',
                    style: TextStyle(
                     
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.black),
                  onPressed: () {},
                ),],
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
                  _buildCategoryButton('ALL', isSelected: true),
                  _buildCategoryButton('SKINCARE', isSelected: false),
                  _buildCategoryButton('HAIR', isSelected: false),
                  _buildCategoryButton('MAKEUP', isSelected: false),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Son gönderileri keşfet.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'İncelemelerini paylaş ve başkalarının incelemelerini keşfet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              
              // Post kategorileri
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Post 1
              _buildPostCard(
                username: 'jess_tk',
                skinType: 'Hassas cilt, akneli, karma cilt',
                brand: 'MAYBELLINE',
                productName: 'Maybelline Lash Sensational Sky High Mascara',
                rating: 4.3,
                reviewCount: '1764 reviews',
                postTitle: 'Kahverengi değil mi?',
                postContent: 'Bu maskara kahverengi değil mi? Benim için çok açık kalıyor. Başka birisi de aynı sorunu yaşadı mı?',
                comments: 1,
                showCommentField: true,
              ),
              
              const SizedBox(height: 20),
              
              // Post 2 - Düzeltilen kısım
              _buildPostCard(
                username: 'beauty.emma',
                skinType: 'Normal cilt, kuru cilt',
                brand: 'CERAVE',
                productName: 'CeraVe Moisturizing Cream',
                rating: 4.8,
                reviewCount: '2453 reviews',
                postTitle: 'Bu kremi denedim!',
                postContent: 'Bu kremi denedim ve gerçekten çok beğendim! Cildim çok kuru olduğu için nemlendirici arıyordum. Bu krem tam istediğim gibi!',
                comments: 4,
                showCommentField: false,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _selectedIndex == 1 ? Colors.blue : Colors.black,
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
    

          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Create Post',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'fsude',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(128, 128, 128, 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
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
                  backgroundColor: Colors.grey,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    
                  ],
                ),
                const Spacer(),
                const Icon(Icons.more_horiz),
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
                        const Text(
                          'Cilt Tipi',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          skinType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Product image
                    Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.photo, color: Colors.grey),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.star, color: Colors.blue[300], size: 18),
                              Icon(Icons.star, color: Colors.blue[300], size: 18),
                              Icon(Icons.star, color: Colors.blue[300], size: 18),
                              Icon(Icons.star, color: Colors.blue[300], size: 18),
                              Icon(Icons.star_half, color: Colors.blue[300], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                reviewCount,
                                style: const TextStyle(
                                  color: Colors.blue,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  postContent,
                  style: const TextStyle(fontSize: 16),
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
                // Like button
                const Icon(Icons.favorite_border),
                
                // Comment button with count
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    const SizedBox(width: 4),
                    Text('$comments'),
                  ],
                ),
                
                // Views count
                Row(
                  children: [
                  ],
                ),
                
                // Share button
                const Icon(Icons.share_outlined),
                
                // Bookmark button
                const Icon(Icons.bookmark_border),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Comment input field (sadece showCommentField true ise göster)
          if (showCommentField)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    // Küçük profil resmi
                    const CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 16,
                      child: Text(
                        'S',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Yorum yazma alanı
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          '1 saat önce',
                          style: TextStyle(
                            color: Colors.grey[600],
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