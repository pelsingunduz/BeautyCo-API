import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:beautyco/theme.dart';
import 'search_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;
  String? _selectedProduct;

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Ogx Düzleştirici Brezilya Keratin Şampuan 385 ml',
      'brand': 'OGX',
      'image': 'assets/images/ogx_sampuan.png',
      'searchTerms': 'ogx keratin şampuan düzleştirici brezilya brazilian',
    },
    {
      'name': 'Ogx Brazilian Keratin Therapy Katı Şampuan 80 gr',
      'brand': 'OGX',
      'image': 'assets/images/ogx_kati_sampuan.png',
      'searchTerms': 'ogx keratin şampuan katı bar brezilya brazilian therapy',
    },
    {
      'name': 'John Frieda Brazilian Sleek Şampuan 250 ml',
      'brand': 'JOHN FRIEDA',
      'image': 'assets/images/john_frieda_sampuan.png',
      'searchTerms': 'john frieda brazilian sleek şampuan düzleştirici',
    },
    {
      'name': 'Nyx Professional Makeup Buttermelt Blush Kremsi Pudra Allık 01 My Butta Half',
      'brand': 'NYX',
      'image': 'assets/images/nyx_allik.png',
      'searchTerms': 'nyx allık pudra kremsi buttermelt blush my butta half makyaj',
    },
  ];

  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = _products;
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product['searchTerms']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: champagneGold,
        elevation: 2,
        shadowColor: darkRed.withOpacity(0.2),
        leading: IconButton(
          icon: Icon(Icons.close, color: primaryRed, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: primaryRed, size: 28),
            const SizedBox(width: 8),
            Text(
              'İnceleme Oluştur',
              style: GoogleFonts.montserrat(
                color: primaryRed,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: lightRed,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: primaryRed, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Hangi ürünü incelemek istersiniz?',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ürün ara...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.search, color: primaryRed, size: 24),
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
                ),
                const SizedBox(height: 20),

                // Ürün listesi
                if (_selectedProduct == null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shadowColor: darkRed.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedProduct = product['name'];
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      product['image'],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product['brand'], style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(
                                        product['name'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                if (_selectedProduct != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Seçilen Ürün',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: primaryRed,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryRed),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              _products.firstWhere((p) => p['name'] == _selectedProduct)['image'],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _selectedProduct!,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Puan verme
                  Text('Puanınız', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w600, color: primaryRed)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: primaryRed,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Başlık ve inceleme
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'İnceleme Başlığı',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'İncelemenizi yazın',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Fotoğraf ekleme logic
                    },
                    icon: Icon(Icons.photo_camera, color: primaryRed),
                    label: Text('Fotoğraf Ekle', style: GoogleFonts.poppins(color: primaryRed)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'product': _selectedProduct,
                        'rating': _rating,
                        'title': _titleController.text,
                        'review': _reviewController.text,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text('İncelemeyi Paylaş', style: GoogleFonts.montserrat(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
