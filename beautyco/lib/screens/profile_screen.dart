import 'package:flutter/material.dart';

void main() {
  runApp(const BeautyCoApp());
}

class BeautyCoApp extends StatelessWidget {
  const BeautyCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeautyCo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Montserrat', // Consistent font family from SearchScreen
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool isFollowing = false;
  late TabController _tabController;
  List<String> favoriteProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Keep the background white like SearchScreen
      appBar: AppBar(
        backgroundColor: Colors.white, // White background for the app bar
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat', // Consistent font family
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            _buildProfileStats(),
            _buildBio(),
            _buildTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.pink.shade100,
                width: 2,
              ),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembe Ünal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat', // Consistent font family
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '@unalpembe',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Montserrat', // Consistent font family
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isFollowing = !isFollowing;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.grey.shade200 : Colors.pink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                      style: TextStyle(
                        color: isFollowing ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat', // Consistent font family
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('İnceleme', '156'),
          _buildVerticalDivider(),
          _buildStat('Takipçi', '2,453'),
          _buildVerticalDivider(),
          _buildStat('Takip', '348'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat', // Consistent font family
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontFamily: 'Montserrat', // Consistent font family
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return SizedBox(
      height: 30,
      width: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(''),
          const SizedBox(height: 6),
          Text(
            'Kuru Cilt, Hassas Cilt, Boyalı Saç',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
              fontFamily: 'Montserrat', // Consistent font family
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.link, size: 16, color: Colors.pink),
              SizedBox(width: 4),
              Text(
                'beautyco.com/unalpembe',
                style: TextStyle(
                  color: Colors.pink,
                  fontFamily: 'Montserrat', // Consistent font family
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Column(
      children: [
        const SizedBox(height: 20),
        TabBar(
          controller: _tabController,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink,
          labelStyle: const TextStyle(
            fontFamily: 'Montserrat', // Consistent font family
          ),
          tabs: const [
            Tab(text: 'İncelemeler'),
            Tab(text: 'Favoriler'),
          ],
        ),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReviewsTab(),
              _buildFavoritesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildReviewItem(index);
      },
    );
  }

  Widget _buildFavoritesTab() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: favoriteProducts.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(favoriteProducts[index]),
          leading: const Icon(Icons.star, color: Colors.pink),
        );
      },
    );
  }

  Widget _buildReviewItem(int index) {
    List<String> products = [
      'Lancome Youth Cream',
      'Dior Forever Foundation',
      'MAC Ruby Woo Lipstick',
      'Nivea Face Moisturizer',
      'La Roche-Posay Sunscreen'
    ];

    List<String> reviews = [
      'Bu kremden gerçekten etkilendim! Cildim daha nemli ve ışıltılı görünüyor.',
      'Hafif yapısı ve doğal bitişiyle en sevdiğim fondötenlerden.',
      'Klasik bir kırmızı ruj, her zaman elimin gittiği ürünlerden biri.',
      'Günlük kullanım için ideal, cildimi nemlendiriyor ama yağlı bırakmıyor.',
      'Güneş koruması yüksek ve cildi tahriş etmiyor. Tavsiye ederim!'
    ];

    return ListTile(
      title: Text(products[index]),
      subtitle: Text(reviews[index]),
      leading: const Icon(Icons.star, color: Colors.pink),
      trailing: IconButton(
        icon: const Icon(Icons.favorite_border, color: Colors.pink),
        onPressed: () {
          setState(() {
            if (!favoriteProducts.contains(products[index])) {
              favoriteProducts.add(products[index]);
            }
          });
        },
      ),
    );
  }
}
