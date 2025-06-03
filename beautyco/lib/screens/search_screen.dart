import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart'; 
import 'create_post.dart';
import 'home_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  // ✅ DÜZELTME 1: Instance yerine static method kullan
  
  bool showClearButton = false;
  bool isLoading = false;
  bool hasSearched = false;
  String? errorMessage;
  
  List<Product> searchResults = [];
  List<Product> allProducts = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        showClearButton = searchController.text.isNotEmpty;
      });
    });
    _loadAllProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Tüm ürünleri yükle (önbellek için)
  Future<void> _loadAllProducts() async {
    try {
      print('Loading all products...');
      // ✅ DÜZELTME 2: Static method kullan
      final productsResponse = await ApiService().getProducts();
      print('Products response: $productsResponse');
      
      if (mounted) {
        setState(() {
          allProducts = productsResponse.map<Product>((productData) {
            return Product.fromJson(productData);
          }).toList();
        });
        print('Loaded ${allProducts.length} products');
      }
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Ürünler yüklenirken hata oluştu: $e';
        });
      }
    }
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      showClearButton = false;
      searchResults.clear();
      hasSearched = false;
      errorMessage = null;
    });
  }

  Future<void> performSearch() async {
    String query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = true;
      errorMessage = null;
    });

    try {
      print('=== SEARCH SCREEN DEBUG ===');
      print('1. Searching for: "$query"');
      print('2. Token exists: ${ApiService.isLoggedIn}');
      
      // ✅ DÜZELTME 3: Instance oluştur ve kullan
      final apiService = ApiService();
      final searchResponse = await apiService.searchProducts(query);
      
      print('3. API search response type: ${searchResponse.runtimeType}');
      print('4. API search response: $searchResponse');
      
      // ✅ DÜZELTME 4: Response'un List olduğunu kontrol et
      if (searchResponse is! List) {
        throw Exception('API response is not a list: ${searchResponse.runtimeType}');
      }
      
      List<Product> results = searchResponse.map<Product>((productData) {
        print('5. Converting product data: $productData');
        return Product.fromJson(productData);
      }).toList();

      if (mounted) {
        setState(() {
          searchResults = results;
          isLoading = false;
        });
      }

      print('6. API search successful. Found ${results.length} results');
      
      // ✅ DÜZELTME 5: Success mesajı göster
      if (results.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${results.length} ürün bulundu'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('7. API search failed: $e');
      print('8. Error type: ${e.runtimeType}');
      
      // API search başarısız olursa, yerel arama yapalım
      try {
        List<Product> results = _performLocalSearch(query);
        
        if (mounted) {
          setState(() {
            searchResults = results;
            isLoading = false;
          });
          
          // Yerel arama kullanıldığını bildir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yerel arama kullanıldı. ${results.length} sonuç bulundu.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        print('9. Local search successful. Found ${results.length} results');
      } catch (localError) {
        print('10. Local search also failed: $localError');
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'Arama yapılırken hata oluştu: $localError';
          });
        }
      }
    }
  }

  List<Product> _performLocalSearch(String query) {
    if (allProducts.isEmpty) {
      throw Exception('Ürün verisi yüklenmemiş');
    }
    
    final queryLower = query.toLowerCase();
    
    return allProducts.where((product) {
      final name = product.name.toLowerCase();
      final brand = (product.brand ?? '').toLowerCase();
      final description = (product.description ?? '').toLowerCase();
      
      return name.contains(queryLower) || 
             brand.contains(queryLower) || 
             description.contains(queryLower);
    }).toList();
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  
  // ✅ DÜZELTME: Home sayfasına git
  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false, // Tüm önceki sayfaları kaldır
    );
  }

  void _showSampleSearches() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Örnek Aramalar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['Chanel', 'Serum', 'Makyaj', 'Cilt Bakımı', 'Parfüm'].map(
              (sample) => ListTile(
                title: Text(sample),
                leading: const Icon(Icons.search),
                onTap: () {
                  Navigator.pop(context);
                  searchController.text = sample;
                  performSearch();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ara',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToHome, // ✅ DÜZELTME: _navigateBack yerine _navigateToHome
        ),
        actions: [
          if (allProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${allProducts.length} ürün',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Arama kutusu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Ürün, marka veya kategori ara...',
                    border: InputBorder.none,
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.grey),
                      onPressed: performSearch,
                    ),
                    suffixIcon: showClearButton
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: clearSearch,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  autofocus: true,
                ),
              ),
            ),
            
            // Debug bilgisi (sadece development için)
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (!ApiService.isLoggedIn)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Giriş yapmanız gerekiyor. Yerel arama kullanılacak.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Sonuçlar
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Aranıyor...'),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aramak istediğiniz ürünü yazın',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (allProducts.isNotEmpty)
              Text(
                '${allProducts.length} ürün arasından arama yapabilirsiniz',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aradığınız kriterlere uygun ürün bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı kelimeler deneyebilirsiniz',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showSampleSearches(),
              child: const Text('Örnek Aramalar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sonuç sayısı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${searchResults.length} sonuç bulundu',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Sonuç listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final product = searchResults[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _buildProductImage(product.productPhoto),
                  title: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brand != null && product.brand!.isNotEmpty)
                        Text(
                          product.brand!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (product.averageRating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.averageRating!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _navigateToProductDetail(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(String? productPhoto) {
    if (productPhoto == null || productPhoto.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image,
          color: Colors.grey[400],
          size: 30,
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          productPhoto,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[400],
                size: 30,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}