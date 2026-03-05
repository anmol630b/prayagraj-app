import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<dynamic> _products   = [];
  List<dynamic> _categories = [];
  bool _isLoading           = true;
  String _searchQuery       = '';
  int? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _loadingItems = {};
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Text('Cart mein add ho gaya!'),
      ]),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
    await ApiService.addToCart(productId, 1);
    if (mounted) setState(() => _loadingItems.remove(productId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(children: [

          // ── Header ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Prayagraj Delivery 🛒',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Row(children: [
                    Icon(Icons.location_on, color: Colors.green.shade600, size: 14),
                    const SizedBox(width: 2),
                    Text('Prayagraj, UP',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ]),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_outlined,
                      color: Colors.green.shade700, size: 22),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) { _searchQuery = val; _loadProducts(); },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _loadProducts();
                            })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ]),
          ),

          // ── Category chips ──────────────────────────────────
          if (_categories.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length + 1,
                  itemBuilder: (_, i) {
                    final isAll    = i == 0;
                    final selected = isAll
                        ? _selectedCategory == null
                        : _selectedCategory == _categories[i - 1]['id'];
                    final label    = isAll ? 'All' : _categories[i - 1]['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory =
                            isAll ? null : _categories[i - 1]['id']);
                        _loadProducts();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selected ? Colors.green.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(label,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.grey.shade600,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          Container(height: 1, color: Colors.grey.shade200),

          // ── Products Grid ───────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _products.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No products found',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                        ]))
                    : RefreshIndicator(
                        color: Colors.green,
                        onRefresh: () async => _loadProducts(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _products.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (_, index) {
                            final product  = _products[index];
                            final isAdding = _loadingItems.contains(product['id']);
                            final imageUrl = product['image_url'];

                            return GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) =>
                                      ProductDetailScreen(product: product))),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // ── Image ──────────────
                                    Expanded(
                                      flex: 5,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(14)),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: imageUrl != null && imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _placeholder(),
                                                )
                                              : _placeholder(),
                                        ),
                                      ),
                                    ),

                                    // ── Info ───────────────
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              product['name'],
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '₹${product['price']}',
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green.shade700),
                                                ),
                                                GestureDetector(
                                                  onTap: isAdding
                                                      ? null
                                                      : () => _addToCart(product['id']),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: isAdding
                                                          ? Colors.green.shade50
                                                          : Colors.green.shade700,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: isAdding
                                                        ? SizedBox(
                                                            height: 14, width: 14,
                                                            child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Colors.green.shade700),
                                                          )
                                                        : const Row(children: [
                                                            Icon(Icons.add, size: 14,
                                                                color: Colors.white),
                                                            SizedBox(width: 3),
                                                            Text('Add',
                                                                style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.bold)),
                                                          ]),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade50,
    child: Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade300),
  );
}