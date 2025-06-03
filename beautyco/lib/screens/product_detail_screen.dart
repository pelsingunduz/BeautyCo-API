import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  
  bool isLoading = true;
  bool isFavorite = false;
  List<Map<String, dynamic>> reviews = [];
  Map<String, dynamic>? categoryInfo;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      // İncelemeleri yükle
      final reviewsResponse = await _apiService.getProductReviews(widget.product.id);
      
      // Kategori bilgisini yükle
      if (widget.product.categoryId != null) {
        final categoriesResponse = await _apiService.getCategories();
        categoryInfo = categoriesResponse.firstWhere(
          (category) => category['id'] == widget.product.categoryId,
          orElse: () => {'id': 0, 'name': 'Genel'},
        );
      }

      if (mounted) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(reviewsResponse);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detaylar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (isFavorite) {
        // Favorilerden çıkar (API'de remove endpoint'i yoksa, bu kısmı atlayabilirsiniz)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorilerden çıkarma özelliği yakında eklenecek'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Favorilere ekle
        await _apiService.addFavorite(widget.product.id);
        if (mounted) {
          setState(() {
            isFavorite = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favorilere eklendi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favori işleminde hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: champagneGold,
        elevation: 0,
        title: Text(
          widget.product.name,
          style: GoogleFonts.montserrat(
            color: primaryRed,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: primaryRed,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [champagneGold, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: isLoading ? _buildLoadingWidget() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryRed),
          const SizedBox(height: 16),
          Text(
            'Ürün detayları yükleniyor...',
            style: GoogleFonts.montserrat(
              color: primaryRed,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          _buildProductInfo(),
          _buildReviewsSection(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkRed.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _buildProductImage(),
          ),
          const SizedBox(height: 20),
          if (widget.product.brand != null && widget.product.brand!.isNotEmpty)
            Text(
              widget.product.brand!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            widget.product.name,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          if (categoryInfo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: lightRed.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categoryInfo!['name'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: primaryRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (widget.product.averageRating != null)
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.product.averageRating!
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.product.averageRating!.toStringAsFixed(1)} (${reviews.length} inceleme)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: widget.product.productPhoto != null && widget.product.productPhoto!.isNotEmpty
            ? Image.network(
                widget.product.productPhoto!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    ),
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
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Widget _buildProductInfo() {
    if (widget.product.description == null || widget.product.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: darkRed.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ürün Bilgisi',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: darkRed.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'İncelemeler',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryRed,
                ),
              ),
              const Spacer(),
              Text(
                '${reviews.length} inceleme',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Henüz inceleme yapılmamış',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewItem(review);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryRed,
                child: Text(
                  review['user']['name'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['user']['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review['rating']
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review['rating'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['review_text'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(review['review_date']),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}