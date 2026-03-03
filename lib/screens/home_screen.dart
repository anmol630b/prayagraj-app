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
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _loadingItems = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  void _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      setState(() => _categories = cats);
    } catch (_) {}
  }

  void _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ApiService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategory,
      );
      setState(() { _products = products; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(int productId) async {
    if (_loadingItems.contains(productId)) return;
    setState(() => _loadingItems.add(productId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 8),
        Text("Cart mein add ho raha hai..."),
      ]),
      backgroundColor: Colors.green,
      duration: Duration(milliseconds: 800),
      behavior: SnackBarBehavior.floating,
    ));
    await ApiService.addToCart(productId, 1);
    if (mounted) setState(() => _loadingItems.remove(productId));
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.green.shade50,
        child: Icon(Icons.shopping_bag, size: 60, color: Colors.green.shade300),
      );
    }
    return Image.network(imageUrl, fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : Center(child: CircularProgressIndicator(color: Colors.green.shade300)),
      errorBuilder: (_, __, ___) => Container(
        color: Colors.green.shade50,
        child: Icon(Icons.shopping_bag, size: 60, color: Colors.green.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // ── Header ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade500],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text('Prayagraj Delivery',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(children: [
                  Icon(Icons.location_on, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Prayagraj', style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (val) { _searchQuery = val; _loadProducts(); },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _loadProducts();
                        })
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ]),
        ),

        // ── Category chips ───────────────────────────────────
        if (_categories.isNotEmpty)
          Container(
            height: 44,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  final selected = _selectedCategory == null;
                  return GestureDetector(
                    onTap: () { setState(() => _selectedCategory = null); _loadProducts(); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? Colors.green.shade700 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? Colors.green.shade700 : Colors.grey.shade300),
                      ),
                      child: Center(child: Text('All',
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600, fontSize: 13))),
                    ),
                  );
                }
                final cat = _categories[i - 1];
                final selected = _selectedCategory == cat['id'];
                return GestureDetector(
                  onTap: () { setState(() => _selectedCategory = cat['id']); _loadProducts(); },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? Colors.green.shade700 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.green.shade700 : Colors.grey.shade300),
                    ),
                    child: Center(child: Text(cat['name'],
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600, fontSize: 13))),
                  ),
                );
              },
            ),
          ),

        // ── Products Grid ────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.green))
              : _products.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Koi product nahi mila',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ]))
                  : RefreshIndicator(
                      color: Colors.green,
                      onRefresh: () async => _loadProducts(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (_, index) {
                          final product = _products[index];
                          final isAdding = _loadingItems.contains(product['id']);
                          return GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    ProductDetailScreen(product: product))),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(
                                    color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                // Image
                                Expanded(
                                  flex: 3,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Stack(fit: StackFit.expand, children: [
                                      _buildImage(product['image_url']),
                                      // Discount badge (if any)
                                      Positioned(
                                        top: 8, left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade700,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('FREE\nDELIVERY',
                                              style: TextStyle(color: Colors.white,
                                                  fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                                // Info
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                      Text(product['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                      Row(children: [
                                        Text('₹${product['price']}',
                                            style: TextStyle(color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold, fontSize: 15)),
                                        const Spacer(),
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const Text('4.5', style: TextStyle(fontSize: 11)),
                                      ]),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 32,
                                        child: ElevatedButton(
                                          onPressed: isAdding ? null : () => _addToCart(product['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                            disabledBackgroundColor: Colors.grey.shade200,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: isAdding
                                              ? const SizedBox(height: 14, width: 14,
                                                  child: CircularProgressIndicator(
                                                      strokeWidth: 2, color: Colors.green))
                                              : const Text('Add to Cart',
                                                  style: TextStyle(color: Colors.white,
                                                      fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}