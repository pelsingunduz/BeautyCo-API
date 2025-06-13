import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  Product? _selectedProduct;
  String _selectedCategory = 'Makyaj'; // Default category
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAuthError = false; // Kimlik doğrulama hatası durumu
  final ApiService _apiService = ApiService();

  List<String> _categories = ['Makyaj', 'Cilt Bakımı', 'Saç', 'Parfüm']; // Default categories

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Map<String, dynamic>> _categoryList = []; // Kategori listesi

  @override
  void initState() {
    super.initState();
    _initializeApiAndLoadData();
  }

  // API'yi başlat ve verileri yükle
  Future<void> _initializeApiAndLoadData() async {
    try {
      // API servisini başlat (token varsa yükle)
      ApiService.init();  
      
      // Login durumunu kontrol et - token kontrolü için alternatif yöntemler:
      // ApiService'deki isLoggedIn getter'ını kullan
      bool isLoggedIn = ApiService.isLoggedIn; 
      
      if (!isLoggedIn) {
        if (mounted) {
          setState(() {
            _isAuthError = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen giriş yapın'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Verileri yükle
      await _loadData();
    } catch (e) {
      print('API initialization error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API başlatma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _isAuthError = false;
    });

    try {
      print('Loading categories and products...');
      
      // Kategori ve ürün verilerini veritabanından çek
      final categoriesResponse = await _apiService.getCategories();
      final productsResponse = await _apiService.getProducts();
      
      // Debug çıktıları
      print('Categories received: ${categoriesResponse.length}');
      print('Categories data: $categoriesResponse');
      print('Products received: ${productsResponse.length}');
      print('Products data: $productsResponse');

      // mounted kontrolü ekleyelim
      if (!mounted) return;

      setState(() {
        _categoryList = List<Map<String, dynamic>>.from(categoriesResponse);
        
        // Ürünleri Product modeline dönüştür - null kontrollü
        _products = productsResponse.map<Product?>((productData) {
          try {
            return Product.fromJson(productData);
          } catch (e) {
            print('Error parsing product: $productData');
            print('Error: $e');
            // Hatalı ürünü atla ve null döndür
            return null;
          }
        }).where((product) => product != null).cast<Product>().toList();

        // Veritabanı entegrasyonu sonrası kategori listesini güncelle
        if (_categoryList.isNotEmpty) {
          _categories = _categoryList.map<String>((category) {
            return category['name']?.toString() ?? 'Bilinmeyen';
          }).toList();
          
          // İlk kategoriyi default olarak seç
          if (_categories.isNotEmpty) {
            _selectedCategory = _categories.first;
          }
        }

        _filteredProducts = List.from(_products);
        _isLoading = false;
        
        print('Final products count: ${_products.length}');
        print('Final categories count: ${_categories.length}');
      });
    } catch (e) {
      print('Load data error: $e');
      print('API Service last error: ${ApiService.lastError}');
      
      // mounted kontrolü ekleyelim
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (e.toString().contains('Authentication required') || 
            e.toString().contains('401')) {
          _isAuthError = true;
        }
      });
      
      String errorMessage = 'Veri yüklenirken hata oluştu';
      if (ApiService.lastError != null) {
        errorMessage = ApiService.lastError!;
      } else {
      errorMessage = '$errorMessage: $e';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Tekrar Dene',
            textColor: Colors.white,
            onPressed: () {
              _initializeApiAndLoadData();
            },
          ),
        ),
      );
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((product) {
          final searchString = '${product.name.toLowerCase()} ${product.brand?.toLowerCase() ?? ""} ${product.description?.toLowerCase() ?? ""}';
          return searchString.contains(query.toLowerCase());
        }).toList();
      }
    });
    print('Filtered products count: ${_filteredProducts.length}');
  }

  // Ürün seçimini temizle ve listeye geri dön
  void _clearProductSelection() {
    setState(() {
      _selectedProduct = null;
      _rating = 0;
      _titleController.clear();
      _reviewController.clear();
      _searchController.clear();
      _filteredProducts = List.from(_products);
    });
  }

  Future<void> _submitReview() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ürün seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir puan verin (1-5)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir inceleme yazın'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _apiService.addReview(
        _selectedProduct!.id,
        _reviewController.text,
        _rating.toInt(),
      );

      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });

      if (response.containsKey('success') && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İncelemeniz başarıyla paylaşıldı!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Ana sayfaya dönerken gerekli verileri gönder
        Navigator.pop(context, {
          'product': _selectedProduct!.name,
          'review': _reviewController.text,
          'category': _selectedCategory,
          'rating': _rating,
          'brand': _selectedProduct!.brand,
          'productPhoto': _selectedProduct!.productPhoto,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: champagneGold,
        elevation: 2,
        shadowColor: darkRed.withAlpha((0.2 * 255).toInt()),
        leading: IconButton(
          icon: Icon(
            _selectedProduct != null ? Icons.arrow_back : Icons.close, 
            color: primaryRed, 
            size: 28
          ),
          onPressed: () {
            if (_selectedProduct != null) {
              // Ürün seçili ise ürün listesine geri dön
              _clearProductSelection();
            } else {
              // Ürün seçili değilse ana sayfaya dön
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: primaryRed, size: 28),
            const SizedBox(width: 8),
            Text(
              _selectedProduct != null ? 'İnceleme Yaz' : 'İnceleme Oluştur',
              style: GoogleFonts.montserrat(
                color: primaryRed,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedProduct == null) // Sadece ürün seçili değilken search butonunu göster
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
          // Debug butonu (geliştirme aşamasında)
          if (true) // Debug modunda göster
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                _initializeApiAndLoadData();
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [champagneGold, Colors.white],
            stops: const [0.0, 0.7],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryRed),
            const SizedBox(height: 16),
            Text(
              'Veriler yükleniyor...',
              style: GoogleFonts.montserrat(
                color: primaryRed,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_isAuthError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Giriş Yapmanız Gerekiyor',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İnceleme oluşturmak için lütfen giriş yapın',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 20.0,
          bottom: 20.0, // Tab bar padding'i kaldırıldı
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedProduct == null) ...[
              _productPromptCard(),
              const SizedBox(height: 20),
              _searchField(),
              const SizedBox(height: 20),
              _productList(),
            ] else ...[
              _selectedProductDetail(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _productPromptCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: lightRed,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryRed.withAlpha((0.3 * 255).toInt())),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: primaryRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hangi ürünü incelemek istersiniz?',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Ürün ara...',
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey[400],
          fontSize: 16,
        ),
        prefixIcon: Icon(Icons.search, color: primaryRed),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: roseGold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: roseGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: _filterProducts,
    );
  }

  Widget _productList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Text(
            'Ürün bulunamadı',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: darkRed,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shadowColor: darkRed.withAlpha((0.1 * 255).toInt()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedProduct = product;
                
                // Ürünün kategorisini seç (eğer varsa)
                if (product.categoryId != null) {
                  final categoryObj = _categoryList.firstWhere(
                    (category) => category['id'] == product.categoryId,
                    orElse: () => {'id': 0, 'name': 'Genel'},
                  );
                  
                  if (_categories.contains(categoryObj['name'])) {
                    _selectedCategory = categoryObj['name'] as String;
                  }
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _productImage(product.productPhoto),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.brand ?? 'Marka bilgisi yok',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 4),
                        Text(product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          product.categoryId != null
                              ? 'Kategori: ${_getCategoryName(product.categoryId!)}'
                              : 'Kategori: Genel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCategoryName(int categoryId) {
    final category = _categoryList.firstWhere(
      (category) => category['id'] == categoryId,
      orElse: () => {'id': 0, 'name': 'Genel'},
    );
    return category['name'] as String;
  }

  Widget _productImage(String? imageUrl) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 40),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: primaryRed,
                      strokeWidth: 2,
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
              ),
      ),
    );
  }

  Widget _selectedProductDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectedProductCard(),
        const SizedBox(height: 30),
        _categorySelector(),
        const SizedBox(height: 24),
        _ratingSelector(),
        const SizedBox(height: 24),
        _reviewInputs(),
        const SizedBox(height: 24),
        _photoUploadButton(),
        const SizedBox(height: 30),
        _submitButton(),
      ],
    );
  }

  Widget _selectedProductCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryRed),
        boxShadow: [
          BoxShadow(
            color: darkRed.withAlpha((0.1 * 255).toInt()),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          _productImage(_selectedProduct!.productPhoto),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _selectedProduct!.brand ?? 'Marka bilgisi yok',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedProduct!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedProduct!.categoryId != null ? 
                  'Kategori: ${_getCategoryName(_selectedProduct!.categoryId!)}' :
                  'Kategori: Genel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _categorySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightRed.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: primaryRed,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : primaryRed,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightRed.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Puanınız',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: primaryRed,
                  size: 42,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          Center(
            child: Text(
              _rating > 0 ? '$_rating/5' : 'Lütfen puan verin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _rating > 0 ? primaryRed : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewInputs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: darkRed.withAlpha((0.05 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'İnceleme Başlığı',
              labelStyle: GoogleFonts.poppins(
                color: primaryRed,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: primaryRed, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _reviewController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'İncelemenizi yazın',
              alignLabelWithHint: true,
              labelStyle: GoogleFonts.poppins(
                color: primaryRed,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: primaryRed, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoUploadButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          // Fotoğraf ekleme fonksiyonu
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf ekleme özelliği yakında eklenecek'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        icon: Icon(Icons.photo_camera, color: primaryRed, size: 26),
        label: Text(
          'Fotoğraf Ekle',
          style: GoogleFonts.poppins(
            color: primaryRed,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryRed, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: lightRed.withAlpha((0.1 * 255).toInt()),
        ),
      ),
    );
  }
  Widget _submitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [primaryRed, darkRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: darkRed.withAlpha((0.3 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'İncelemeni Paylaş',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }
}