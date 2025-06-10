import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Null ise current user, değilse specified user
  final bool isCurrentUser; // Giriş yapan kullanıcının profili mi?
  
  const ProfileScreen({
    super.key,
    this.userId,
    this.isCurrentUser = true,
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  User? userData;
  List<dynamic> userReviews = [];
  List<dynamic> userFavorites = [];
  List<dynamic> followers = [];
  List<dynamic> following = [];
  
  bool isLoading = true;
  bool isFollowersLoading = false;
  bool isFollowingLoading = false;
  String? errorMessage;
  String? currentUserId; // Giriş yapan kullanıcının ID'si
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUserId();
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Giriş yapan kullanıcının ID'sini al
  Future<void> _loadCurrentUserId() async {
    try {
      currentUserId = await _apiService.getCurrentUserId();
      debugPrint('Current user ID: $currentUserId');
    } catch (e) {
      debugPrint('Current user ID alınırken hata: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      String? targetUserId;
      
      if (widget.userId != null) {
        // Belirli bir kullanıcının profili
        targetUserId = widget.userId!;
      } else {
        // Current user'ın profili
        targetUserId = await _apiService.getCurrentUserId();
        
        // Eğer current_user_id yoksa, kullanıcıyı login sayfasına yönlendir
        if (targetUserId == null) {
          setState(() {
            errorMessage = 'Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.';
            isLoading = false;
          });
          return;
        }
      }

      debugPrint('Loading profile for user ID: $targetUserId');
      
      // Kullanıcı profilini yükle
      userData = await _apiService.getUserProfile(targetUserId);
      
      // Takip durumunu kontrol et (eğer başka birinin profili ise)
      if (!_isCurrentUserProfile && currentUserId != null) {
        await _checkFollowStatus(targetUserId);
      }
      
      // Takipçi ve takip edilen listelerini yükle
      await _loadFollowData(targetUserId);
      
      // Favorileri yükle (sadece kendi profilimiz ise)
      if (_isCurrentUserProfile) {
        await _loadFavorites();
      }
      
      setState(() {
        isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
      debugPrint('Profile loading error: $e');
    }
  }

  // Takip durumunu kontrol et
  Future<void> _checkFollowStatus(String targetUserId) async {
    try {
      final followingList = await _apiService.getFollowing(currentUserId!);
      isFollowing = followingList.any((user) => user['id'].toString() == targetUserId);
    } catch (e) {
      debugPrint('Follow status check error: $e');
    }
  }

  // Takipçi ve takip edilen verilerini yükle
  Future<void> _loadFollowData(String userId) async {
    try {
      final followersData = await _apiService.getFollowers(userId);
      final followingData = await _apiService.getFollowing(userId);
      
      setState(() {
        followers = followersData;
        following = followingData;
      });
    } catch (e) {
      debugPrint('Follow data loading error: $e');
    }
  }

  // Favorileri yükle
  Future<void> _loadFavorites() async {
    try {
      userFavorites = await _apiService.getFavorites();
    } catch (e) {
      debugPrint('Favorites loading error: $e');
    }
  }

  // Takip/takipten çık işlemi
  Future<void> _toggleFollow() async {
    if (userData == null || currentUserId == null) return;
    
    try {
      final targetUserId = userData!.id.toString();
      
      Map<String, dynamic> result;
      if (isFollowing) {
        result = await _apiService.unfollowUser(targetUserId);
      } else {
        result = await _apiService.followUser(targetUserId);
      }
      
      if (result['success']) {
        setState(() {
          isFollowing = !isFollowing;
        });
        
        // Takipçi sayısını güncelle
        await _loadFollowData(targetUserId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFollowing ? 'Takip edildi' : 'Takipten çıkarıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(int productId) async {
    try {
      final result = await _apiService.removeFavorite(productId);
      
      if (result['success']) {
        await _loadFavorites(); // Favorileri yeniden yükle
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ürün favorilerden kaldırıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Profil sahibi current user mı kontrol et
  bool get _isCurrentUserProfile {
    if (userData == null || currentUserId == null) return widget.isCurrentUser;
    return userData!.id.toString() == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isCurrentUserProfile ? 'Profil' : 'Kullanıcı Profili',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          if (_isCurrentUserProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black),
              onPressed: () {
                // Ayarlar sayfasına yönlendirme
                Navigator.pushNamed(context, '/settings');
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : errorMessage != null
              ? _buildErrorState()
              : userData == null
                  ? const Center(child: Text('Profil bulunamadı'))
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Profil yüklenemedi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (userData == null) return const SizedBox();
    
    final isCurrentUser = _isCurrentUserProfile;
    
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
              image: userData!.profilePhoto != null
                  ? DecorationImage(
                      image: NetworkImage(userData!.profilePhoto!),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {
                        // Resim yüklenemezse varsayılan avatar göster
                      },
                    )
                  : null,
            ),
            child: userData!.profilePhoto == null 
                ? const Icon(Icons.person, size: 50, color: Colors.pink) 
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userData!.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 12),
                // Buton: Kendi profili ise "Profili Düzenle", başkasının profili ise "Takip Et/Takipten Çık"
                GestureDetector(
                  onTap: isCurrentUser 
                      ? () {
                          // Profil düzenleme sayfasına yönlendirme
                          Navigator.pushNamed(context, '/edit-profile');
                        }
                      : _toggleFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.pink : isFollowing ? Colors.grey : Colors.pink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCurrentUser 
                          ? 'Profili Düzenle'
                          : isFollowing ? 'Takipten Çık' : 'Takip Et',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
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
          GestureDetector(
            onTap: () {
              // İncelemeleri göster
              _showReviewsDialog();
            },
            child: _buildStat('İnceleme', userData!.reviewCount.toString()),
          ),
          _buildVerticalDivider(),
          GestureDetector(
            onTap: () {
              // Takipçileri göster
              _showFollowersDialog();
            },
            child: _buildStat('Takipçi', followers.length.toString()),
          ),
          _buildVerticalDivider(),
          GestureDetector(
            onTap: () {
              // Takip edilenleri göster
              _showFollowingDialog();
            },
            child: _buildStat('Takip', following.length.toString()),
          ),
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
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontFamily: 'Montserrat',
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
    if (userData?.createdAt == null) return const SizedBox();
    
    final createdAt = userData!.createdAt!;
    final joinDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BeautyCo üyesi - $joinDate tarihinden beri',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: Colors.pink),
              const SizedBox(width: 4),
              Text(
                userData!.email,
                style: const TextStyle(
                  color: Colors.pink,
                  fontFamily: 'Montserrat',
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
            fontFamily: 'Montserrat',
          ),
          tabs: const [
            Tab(text: 'İncelemeler'),
            Tab(text: 'Favoriler'),
          ],
        ),
        SizedBox(
          height: 400,
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
    final reviews = userData?.reviews ?? [];
    
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _isCurrentUserProfile ? 'Henüz inceleme yapmadınız' : 'Henüz inceleme yapmamış',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        // Convert Review object to Map for backward compatibility
        final reviewData = _reviewToMap(reviews[index]);
        return _buildReviewItem(reviewData);
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (userFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _isCurrentUserProfile ? 'Henüz favori ürününüz yok' : 'Henüz favori ürünü yok',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: userFavorites.length,
      itemBuilder: (context, index) {
        return _buildFavoriteItem(userFavorites[index]);
      },
    );
  }

  // Helper method to convert Review object to Map
  Map<String, dynamic> _reviewToMap(dynamic review) {
    if (review is Map<String, dynamic>) {
      return review;
    }
    // If review is a Review object, convert it to Map
    // Adjust this based on your Review model structure
    return {
      'product_name': review.productName ?? '',
      'brand': review.brand ?? '',
      'rating': review.rating ?? 0,
      'review_text': review.reviewText ?? '',
      'review_date': review.createdAt?.toIso8601String() ?? '',
      'product_photo': review.productPhoto ?? '',
    };
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final reviewDate = DateTime.tryParse(review['review_date'] ?? '') ?? DateTime.now();
    final formattedDate = '${reviewDate.day}/${reviewDate.month}/${reviewDate.year}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review['product_photo'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['product_name'] ?? 'Ürün Adı',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Text(
                        review['brand'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (review['rating'] ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['review_text'] ?? '',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            favorite['product_photo'] ?? '',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              );
            },
          ),
        ),
        title: Text(
          favorite['name'] ?? 'Ürün Adı',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              favorite['brand'] ?? '',
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Montserrat',
              ),
            ),
            if (favorite['average_rating'] != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  Text(
                    favorite['average_rating'].toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: _isCurrentUserProfile 
            ? IconButton(
                icon: const Icon(Icons.favorite, color: Colors.pink),
                onPressed: () => _toggleFavorite(favorite['product_id'] ?? favorite['id']),
              )
            : null,
      ),
    );
  }

  // Takipçileri göster
  void _showFollowersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Takipçiler (${followers.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: followers.isEmpty
                ? const Center(child: Text('Henüz takipçi yok'))
                : ListView.builder(
                    itemCount: followers.length,
                    itemBuilder: (context, index) {
                      final follower = followers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: follower['profile_photo'] != null
                              ? NetworkImage(follower['profile_photo'])
                              : null,
                          child: follower['profile_photo'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(follower['name'] ?? 'İsimsiz'),
                        subtitle: Text(follower['email'] ?? ''),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  // Takip edilenleri göster
  void _showFollowingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Takip Edilenler (${following.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: following.isEmpty
                ? const Center(child: Text('Henüz kimseyi takip etmiyor'))
                : ListView.builder(
                    itemCount: following.length,
                    itemBuilder: (context, index) {
                      final followedUser = following[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: followedUser['profile_photo'] != null
                              ? NetworkImage(followedUser['profile_photo'])
                              : null,
                          child: followedUser['profile_photo'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(followedUser['name'] ?? 'İsimsiz'),
                        subtitle: Text(followedUser['email'] ?? ''),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  // İncelemeleri göster
  void _showReviewsDialog() {
    final reviews = userData?.reviews ?? [];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tüm İncelemeler (${reviews.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: reviews.isEmpty
                ? const Center(child: Text('Henüz inceleme yok'))
                : ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final reviewData = _reviewToMap(reviews[index]);
                      return _buildReviewItem(reviewData);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
}