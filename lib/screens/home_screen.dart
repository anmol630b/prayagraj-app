import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _loadingItems = {}; // Kaunsa product add ho raha hai track karo

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    try {
      final products = await ApiService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(int productId) async {
    if (_loadingItems.contains(productId)) return; // Double tap prevent karo

    setState(() => _loadingItems.add(productId));

    // UI turant snackbar dikhao, API background mein
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text("Cart mein add ho raha hai..."),
        ]),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await ApiService.addToCart(productId, 1);

    if (mounted) {
      setState(() => _loadingItems.remove(productId));
    }
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.green.shade50,
        child: Icon(Icons.shopping_bag, size: 60, color: Colors.green.shade300),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(child: CircularProgressIndicator(color: Colors.green.shade300));
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.green.shade50,
          child: Icon(Icons.shopping_bag, size: 60, color: Colors.green.shade300),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.greenAccent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🛒 Prayagraj Delivery",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadProducts();
                  },
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text("Koi product nahi mila"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isAdding = _loadingItems.contains(product['id']);
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                      child: _buildImage(product['image_url']),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "₹${product['price']}",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ElevatedButton(
                                          onPressed: isAdding ? null : () => _addToCart(product['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isAdding ? Colors.grey.shade300 : Colors.green,
                                            minimumSize: const Size(double.infinity, 36),
                                          ),
                                          child: isAdding
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.green,
                                                  ),
                                                )
                                              : const Text("Add to Cart"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}