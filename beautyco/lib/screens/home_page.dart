import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:beautyco/screens/profile_screen.dart';
import 'package:beautyco/screens/create_post.dart';
import 'package:beautyco/screens/search_screen.dart';
import 'package:beautyco/theme.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'TÜM';
  final TextEditingController _commentController = TextEditingController();
  Set<int> _favoritedProductIds = {};
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _currentUserId;

  List<Map<String, dynamic>> _posts = [];

  final List<String> _categories = [
    'TÜM',
    'Makyaj',
    'Cilt Bakımı',
    'Saç',
    'Parfüm',
    'Kişisel Bakım',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await ApiService.init();
    _currentUserId = await _apiService.getCurrentUserId();
    await _fetchFeedPosts();
    await _fetchFavoritedProducts();
  }

  Future<void> _fetchFavoritedProducts() async {
    try {
      final fetchedFavorites = await _apiService.getFavorites();
      setState(() {
        _favoritedProductIds =
            fetchedFavorites
                .map<int>((fav) => fav['product_id'] as int)
                .toSet();
      });
    } catch (e) {
      debugPrint('Favori ürünleri çekerken hata: $e');
    }
  }

  Future<void> _fetchFeedPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedPosts = await _apiService.getFeedPosts();
      setState(() {
        _posts =
            fetchedPosts.map<Map<String, dynamic>>((post) {
              return {
                'username': post['username'] ?? 'Bilinmeyen Kullanıcı',
                'product': post['product_name'] ?? 'Ürün Adı',
                'content': post['content'] ?? 'İnceleme metni yok.',
                'category': post['category_name'] ?? 'Genel',
                'showCommentField': false,
                'comments': [],
                'rating': post['rating'] ?? 0.0,
                'brand': post['brand'] ?? 'Marka Yok',
                'productPhoto': post['product_photo'] ?? '',
                'product_id': post['product_id'],
              };
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ana sayfa gönderileri yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gönderiler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _posts.insert(0, {
            'username': result['username'] ?? 'Sen',
            'product': result['product'],
            'content': result['review'],
            'category': result['category'],
            'rating': result['rating'],
            'brand': result['brand'],
            'productPhoto': result['productPhoto'],
            'comments': [],
            'showCommentField': false,
            'product_id': null,
          });
          _selectedCategory = 'TÜM';
          _selectedIndex = 0;
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ), // ↑ vertical 8 → 10 yapıldı
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryRed : roseGold,
            width: 1,
          ),
        ),
        child: Center(
          // ← BU ÖNEMLİ
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              color: isSelected ? Colors.white : primaryRed,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14, // isteğe göre küçültüp büyütebilirsin
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final int? productId = post['product_id'] as int?;

    return Stack(
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
                            post['username'] ?? 'Anonim',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${post['brand'] ?? ''} - ${post['product'] ?? 'Ürün Adı'}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (post['rating'] != null && post['rating'] > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.star, color: primaryRed, size: 16),
                                  Text(
                                    ' ${post['rating'].toStringAsFixed(1)}',
                                    style: GoogleFonts.montserrat(
                                      color: primaryRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        productId != null &&
                                _favoritedProductIds.contains(productId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.pink,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (productId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ürün ID\'si bulunamadı.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          if (_favoritedProductIds.contains(productId)) {
                            await _apiService.removeFavorite(productId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Favorilerden çıkarıldı'),
                                backgroundColor: Colors.pink,
                              ),
                            );
                          } else {
                            await _apiService.addFavorite(productId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Favorilere eklendi'),
                                backgroundColor: Colors.pink,
                              ),
                            );
                          }
                          await _fetchFavoritedProducts();
                        } catch (e) {
                          debugPrint('Favori işlemi hatası: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Favori işlemi sırasında hata oluştu: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (post['productPhoto'] != null &&
                    post['productPhoto'].isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(post['productPhoto']),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          debugPrint('Resim yüklenirken hata: $exception');
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.photo, size: 50, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  post['content'] ?? 'İnceleme metni bulunamadı.',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kategori: ${post['category'] ?? 'Belirtilmemiş'}',
                      style: GoogleFonts.montserrat(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _posts[index]['showCommentField'] =
                              !post['showCommentField'];
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
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Yorumunuzu yazın...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(8),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: primaryRed),
                            onPressed: () {
                              if (_commentController.text.trim().isNotEmpty) {
                                setState(() {
                                  if (!_posts[index].containsKey('comments')) {
                                    _posts[index]['comments'] = [];
                                  }
                                  _posts[index]['comments'].add({
                                    'username': 'sen',
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
                      if (post['comments'] != null &&
                          post['comments'].isNotEmpty)
                        Column(
                          children: [
                            const Divider(),
                            ...post['comments']
                                .map<Widget>(
                                  (comment) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const CircleAvatar(
                                          radius: 12,
                                          child: Icon(Icons.person, size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts =
        _selectedCategory == 'TÜM'
            ? _posts
            : _posts
                .where((post) => post['category'] == _selectedCategory)
                .toList();

    final List<Widget> _screens = [
      _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryRed))
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12), // ← AppBar ile kategori arası boşluk
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _categories.length,
                  itemBuilder:
                      (context, index) =>
                          _buildCategoryButton(_categories[index]),
                ),
              ),
              const Divider(),
              Expanded(
                child:
                    filteredPosts.isEmpty
                        ? Center(
                          child: Text(
                            'Henüz gönderi yok.',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: filteredPosts.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildPostCard(filteredPosts[index], index),
                        ),
              ),
            ],
          ),
      const CreatePostScreen(),
      const SearchScreen(),
      ProfileScreen(isCurrentUser: true),
    ];

    return Scaffold(
      appBar: _buildAppBar(),
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

  AppBar _buildAppBar() {
    if (_selectedIndex == 3) {
      return AppBar(
        backgroundColor: champagneGold,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Profil',
            style: TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: primaryRed),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5), // AppBar'a minimum etki
          child: Divider(
            height: 0.5, // Daha yukarı yerleşsin
            thickness: 1,
            color: Colors.black12,
          ),
        ),
      );
    } else {
      return AppBar(
        backgroundColor: primaryRed,
        centerTitle: true,
        title: Text(
          'BeautyCo',
          style: GoogleFonts.pacifico(color: Colors.white),
        ),
      );
    }
  }
}
