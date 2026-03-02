import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';

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
  String _sortBy = 'newest';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final products = await ApiService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategory,
        sort: _sortBy,
      );
      final categories = await ApiService.getCategories();
      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addToCart(int productId, String name) async {
    final success = await ApiService.addToCart(productId, 1);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('$name cart mein add ho gaya!'),
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.green.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('🛒 Prayagraj Delivery',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OrderScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      ApiService.username.isNotEmpty
                          ? ApiService.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  _searchQuery = val;
                  _loadData();
                },
                decoration: InputDecoration(
                  hintText: 'Products dhundo...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _loadData();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final isSelected = isAll
                      ? _selectedCategory == null
                      : _categories[index - 1]['id'] == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = isAll ? null : _categories[index - 1]['id'];
                      });
                      _loadData();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green.shade700 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        isAll ? 'All' : _categories[index - 1]['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Sort & Count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_products.length} products',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort, color: Colors.green),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                    ],
                    onChanged: (val) {
                      setState(() => _sortBy = val!);
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Products Grid
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.green)),
                )
              : _products.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('Koi product nahi mila',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _products[index];
                            final imageUrl = product['image_url'];
                            return _buildProductCard(product, imageUrl);
                          },
                          childCount: _products.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage())
                  : _placeholderImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product['description'] ?? '',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${product['price']}',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => _addToCart(product['id'], product['name']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.green.shade50,
      child: Icon(Icons.shopping_bag, size: 60, color: Colors.green.shade300),
    );
  }
}