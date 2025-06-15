import 'package:beautyco/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart' hide Product; // Product'ı user.dart'tan gizle
import '../models/product.dart'; // Product'ı product.dart'tan al
import 'edit_profile_screen.dart';
import 'package:intl/intl.dart';
import 'product_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    this.userId,
    this.isCurrentUser = false, // Varsayılan olarak false yapıldı
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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
  String? currentUserId;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    debugPrint(
      'ProfileScreen initState - userId: ${widget.userId}, isCurrentUser: ${widget.isCurrentUser}',
    );
    _initializeProfile();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget parametreleri değiştiğinde profili yeniden yükle
    if (oldWidget.userId != widget.userId ||
        oldWidget.isCurrentUser != widget.isCurrentUser) {
      debugPrint('ProfileScreen didUpdateWidget - Reloading profile');
      _initializeProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Ana başlatma fonksiyonu
  Future<void> _initializeProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        // Önceki verileri temizle
        userData = null;
        userReviews = [];
        userFavorites = [];
        followers = [];
        following = [];
        isFollowing = false;
      });

      // Önce current user ID'sini al
      await _loadCurrentUserId();

      // Sonra profil verilerini yükle
      await _loadProfile();
    } catch (e) {
      debugPrint('Profile initialization error: $e');
      setState(() {
        errorMessage = 'Profil yüklenirken hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      // Her seferinde fresh current user ID al
      currentUserId = await _apiService.getCurrentUserId();
      debugPrint('✅ Current user ID loaded: $currentUserId');

      if (currentUserId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
    } catch (e) {
      debugPrint('❌ Current user ID loading error: $e');
      throw e;
    }
  }

  Future<void> _loadProfile() async {
    try {
      String? targetUserId;

      // Hangi kullanıcının profilini yükleyeceğimizi belirle
      if (widget.userId != null && widget.userId!.isNotEmpty) {
        // Belirli bir kullanıcının profili
        targetUserId = widget.userId!;
        debugPrint('📋 Loading specific user profile: $targetUserId');
      } else if (widget.isCurrentUser ||
          (widget.userId == null || widget.userId!.isEmpty)) {
        // Current user'ın profili
        targetUserId = currentUserId;
        debugPrint('👤 Loading current user profile: $targetUserId');
      } else {
        // Fallback
        targetUserId = currentUserId;
        debugPrint('🔄 Fallback to current user profile: $targetUserId');
      }

      if (targetUserId == null || targetUserId.isEmpty) {
        throw Exception('Kullanıcı ID\'si bulunamadı');
      }

      debugPrint('🔄 Loading profile for user ID: $targetUserId');

      // Kullanıcı profilini yükle - her seferinde fresh data al
      userData = await _apiService.getUserProfile(targetUserId);
      debugPrint(
        '✅ User data loaded: ${userData?.name} (${userData?.email}) - ID: ${userData?.id}',
      );

      // Takip durumunu kontrol et (eğer başka birinin profili ise)
      if (!_isCurrentUserProfile && currentUserId != null) {
        await _checkFollowStatus(targetUserId);
        debugPrint('📊 Follow status checked: $isFollowing');
      }

      // Takipçi ve takip edilen listelerini yükle
      await _loadFollowData(targetUserId);
      debugPrint(
        '👥 Follow data loaded - Followers: ${followers.length}, Following: ${following.length}',
      );

      // Favorileri yükle (sadece kendi profilimiz ise)
      if (_isCurrentUserProfile) {
        await _loadFavorites();
        debugPrint('❤️ Favorites loaded: ${userFavorites.length}');
      }

      setState(() {
        isLoading = false;
      });

      debugPrint('🎉 Profile loading completed successfully');
    } catch (e) {
      debugPrint('❌ Profile loading error: $e');
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _checkFollowStatus(String targetUserId) async {
    try {
      final followingList = await _apiService.getFollowing(currentUserId!);
      isFollowing = followingList.any(
        (user) => user['id'].toString() == targetUserId,
      );
      debugPrint('Follow status for $targetUserId: $isFollowing');
    } catch (e) {
      debugPrint('Follow status check error: $e');
    }
  }

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
      // Bu hata kritik değil, profil yüklemeye devam edebiliriz
    }
  }

  Future<void> _loadFavorites() async {
    try {
      userFavorites = await _apiService.getFavorites();
    } catch (e) {
      debugPrint('Favorites loading error: $e');
      // Bu hata kritik değil, profil yüklemeye devam edebiliriz
    }
  }

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

        await _loadFollowData(targetUserId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFollowing ? 'Takip edildi' : 'Takipten çıkarıldı',
              ),
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
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleFavorite(int productId) async {
    try {
      final result = await _apiService.removeFavorite(productId);

      if (result['success']) {
        await _loadFavorites();

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
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool get _isCurrentUserProfile {
    if (userData == null || currentUserId == null) {
      debugPrint(
        '⚠️ Cannot determine if current user profile - userData: ${userData != null}, currentUserId: ${currentUserId != null}',
      );
      return widget.isCurrentUser;
    }

    final isCurrentUser = userData!.id.toString() == currentUserId;
    debugPrint(
      '🔍 Is current user profile: $isCurrentUser (userData.id: ${userData!.id}, currentUserId: $currentUserId)',
    );
    return isCurrentUser;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: primaryRed))
        : errorMessage != null
        ? _buildErrorState()
        : userData == null
        ? _buildNoDataState()
        : RefreshIndicator(
          onRefresh: _initializeProfile,
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
        );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Profil bulunamadı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Kullanıcı bilgileri yüklenemedi',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
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
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
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
              border: Border.all(color: primaryRed, width: 2),
              image:
                  userData!.profilePhoto != null
                      ? DecorationImage(
                        image: NetworkImage(userData!.profilePhoto!),
                        fit: BoxFit.cover,
                        onError: (error, stackTrace) {
                          debugPrint('Profile photo load error: $error');
                        },
                      )
                      : null,
            ),
            child:
                userData!.profilePhoto == null
                    ? const Icon(Icons.person, size: 50, color: primaryRed)
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
                GestureDetector(
                  onTap:
                      isCurrentUser
                          ? () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EditProfileScreen(
                                      userId: userData!.id.toString(),
                                      currentName: userData!.name,
                                      currentProfilePhoto:
                                          userData!.profilePhoto,
                                    ),
                              ),
                            );

                            if (result == true) {
                              _initializeProfile();
                            }
                          }
                          : _toggleFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser
                              ? primaryRed
                              : isFollowing
                              ? Colors.grey
                              : primaryRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCurrentUser
                          ? 'Profili Düzenle'
                          : isFollowing
                          ? 'Takipten Çık'
                          : 'Takip Et',
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
              _showReviewsDialog();
            },
            child: _buildStat('İnceleme', userData!.reviewCount.toString()),
          ),
          _buildVerticalDivider(),
          GestureDetector(
            onTap: () {
              _showFollowersDialog();
            },
            child: _buildStat('Takipçi', followers.length.toString()),
          ),
          _buildVerticalDivider(),
          GestureDetector(
            onTap: () {
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
          style: const TextStyle(color: Colors.grey, fontFamily: 'Montserrat'),
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
              const Icon(Icons.email, size: 16, color: primaryRed),
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
          labelStyle: const TextStyle(fontFamily: 'Montserrat'),
          tabs: const [Tab(text: 'İncelemeler'), Tab(text: 'Favoriler')],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [_buildReviewsTab(), _buildFavoritesTab()],
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
            const Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isCurrentUserProfile
                  ? 'Henüz inceleme yapmadınız'
                  : 'Henüz inceleme yapmış',
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
        final review = reviews[index];
        return _buildReviewItem(review);
      },
    );
  }

  Widget _buildFavoritesTab() {
    final allFavorites = [...userFavorites];
    if (allFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _isCurrentUserProfile
                  ? 'Henüz favori ürününüz yok'
                  : 'Henüz favori ürünü yok',
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
      itemCount: allFavorites.length,
      itemBuilder: (context, index) {
        final favorite = allFavorites[index];
        if (favorite.containsKey('content')) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              onTap: () {
                final dynamic rawProductId =
                    favorite['product_id'] ?? favorite['id'];
                int? parsedProductId;

                if (rawProductId is int) {
                  parsedProductId = rawProductId;
                } else if (rawProductId is String) {
                  parsedProductId = int.tryParse(rawProductId);
                }

                if (parsedProductId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Favori yorumu için ürün ID'si bulunamadı veya geçersiz.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  debugPrint(
                    "DEBUG: Favori yorumu için ürün ID'si null veya geçersiz. rawProductId: $rawProductId",
                  );
                  return;
                }

                debugPrint(
                  'DEBUG: Before Product constructor (review tab) - parsedProductId: $parsedProductId (type: ${parsedProductId.runtimeType})',
                );
                final int productIdForReviewNav = parsedProductId as int;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProductDetailScreen(
                          product: Product(
                            id: parsedProductId ?? 0,
                            name:
                                favorite['product_name'] ??
                                favorite['name'] ??
                                'Ürün Adı',
                            brand: favorite['brand'],
                            description: favorite['description'],
                            categoryId: favorite['category_id'],
                            averageRating:
                                favorite['average_rating']?.toDouble(),
                            productPhoto: favorite['product_photo'],
                          ),
                        ),
                  ),
                );
              },
              leading: const Icon(Icons.favorite, color: Colors.pink),
              title: Text(
                favorite['product_name'] ?? favorite['name'] ?? 'Ürün Adı',
              ),
              subtitle: Text(favorite['content'] ?? ''),
            ),
          );
        }
        return _buildFavoriteItem(favorite);
      },
    );
  }

  Widget _buildReviewItem(Review review) {
    final formattedDate = DateFormat('dd.MM.yyyy').format(review.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.product?.name ?? 'Ürün Adı',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            review.content,
            style: const TextStyle(fontSize: 14, fontFamily: 'Montserrat'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                ),
              ),
              if (_isCurrentUserProfile)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('İncelemeyi Sil'),
                            content: const Text(
                              'Bu incelemeyi silmek istediğinize emin misiniz?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('İptal'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text('Sil'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      try {
                        final result = await _apiService.deleteReview(
                          review.id,
                        );

                        if (result['success'] == true) {
                          // Sadece user profile'ı yeniden yükle
                          if (userData != null) {
                            final updatedUserData = await _apiService
                                .getUserProfile(userData!.id.toString());
                            setState(() {
                              userData = updatedUserData;
                            });
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('İnceleme silindi'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'Silme işlemi başarısız',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Silme hatası: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () {
          final dynamic rawProductId = favorite['product_id'] ?? favorite['id'];
          int? parsedProductId;

          if (rawProductId is int) {
            parsedProductId = rawProductId;
          } else if (rawProductId is String) {
            parsedProductId = int.tryParse(rawProductId);
          }

          if (parsedProductId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ürün ID'si bulunamadı veya geçersiz."),
                backgroundColor: Colors.red,
              ),
            );
            debugPrint(
              "DEBUG: Ürün ID'si null veya geçersiz. rawProductId: $rawProductId",
            );
            return;
          }

          debugPrint(
            'DEBUG: Before Product constructor (favorite item) - parsedProductId: $parsedProductId (type: ${parsedProductId.runtimeType})',
          );
          final int productIdForNavigation = parsedProductId as int;

          // Ürün detay sayfasına yönlendir
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProductDetailScreen(
                    product: Product(
                      id: parsedProductId ?? 0,
                      name: favorite['name'] ?? 'Ürün Adı',
                      brand: favorite['brand'],
                      description: favorite['description'],
                      categoryId: favorite['category_id'],
                      averageRating: favorite['average_rating']?.toDouble(),
                      productPhoto: favorite['product_photo'],
                    ),
                  ),
            ),
          );
        },
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
        trailing:
            _isCurrentUserProfile
                ? IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.pink),
                  onPressed: () {
                    final dynamic rawProductId =
                        favorite['product_id'] ?? favorite['id'];
                    int? parsedProductId;

                    if (rawProductId is int) {
                      parsedProductId = rawProductId;
                    } else if (rawProductId is String) {
                      parsedProductId = int.tryParse(rawProductId);
                    }

                    if (parsedProductId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Favori kaldırmak için ürün ID'si bulunamadı veya geçersiz.",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      debugPrint(
                        "DEBUG: Favori kaldırma için ürün ID'si null veya geçersiz. rawProductId: $rawProductId",
                      );
                      return;
                    }
                    debugPrint(
                      'DEBUG: Before _toggleFavorite - parsedProductId: $parsedProductId (type: ${parsedProductId.runtimeType})',
                    );
                    final int productIdForToggle = parsedProductId as int;
                    _toggleFavorite(productIdForToggle);
                  },
                )
                : null,
      ),
    );
  }

  void _showFollowersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Takipçiler (${followers.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child:
                followers.isEmpty
                    ? const Center(child: Text('Henüz takipçi yok'))
                    : ListView.builder(
                      itemCount: followers.length,
                      itemBuilder: (context, index) {
                        final follower = followers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                follower['profile_photo'] != null
                                    ? NetworkImage(follower['profile_photo'])
                                    : null,
                            child:
                                follower['profile_photo'] == null
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

  void _showFollowingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Takip Edilenler (${following.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child:
                following.isEmpty
                    ? const Center(child: Text('Henüz kimseyi takip etmiyor'))
                    : ListView.builder(
                      itemCount: following.length,
                      itemBuilder: (context, index) {
                        final followedUser = following[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                followedUser['profile_photo'] != null
                                    ? NetworkImage(
                                      followedUser['profile_photo'],
                                    )
                                    : null,
                            child:
                                followedUser['profile_photo'] == null
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
            child:
                reviews.isEmpty
                    ? const Center(child: Text('Henüz inceleme yok'))
                    : ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return _buildReviewItem(review);
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
