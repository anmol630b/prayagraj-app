import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity   = 1;
  bool _isLoading = false;
  bool _wishlisted = false;
  double _avgRating = 0;
  int _totalRatings = 0;
  List<dynamic> _ratings = [];
  bool _ratingsLoaded = false;

  double get _total =>
      double.parse(widget.product['price'].toString()) * _quantity;


  @override
  void initState() {
    super.initState();
    _loadRatings();
    _loadWishlistStatus();
  }

  void _toggleWishlist() async {
    final result = await ApiService.toggleWishlist(widget.product['id'], _wishlisted);
    if (mounted) setState(() => _wishlisted = result['wishlisted'] ?? false);
  }

  Future<void> _loadWishlistStatus() async {
    try {
      final wishlist = await ApiService.getWishlist();
      final isWishlisted = wishlist.any((w) => w['product_id'] == widget.product['id']);
      if (mounted) setState(() => _wishlisted = isWishlisted);
    } catch (e) {}
  }

  void _loadRatings() async {
    try {
      final data = await ApiService.getProductRatings(widget.product['id']);
      if (mounted) setState(() {
        _avgRating = (data['average'] ?? 0).toDouble();
        _totalRatings = data['total'] ?? 0;
        _ratings = data['ratings'] ?? [];
        _ratingsLoaded = true;
      });
    } catch (e) {}
  }

    @override
  Widget build(BuildContext context) {
    final p           = widget.product;
    final imageUrl    = p['image_url'];
    final isAvailable = p['is_available'] == true;
    final price       = double.parse(p['price'].toString());
    final mrp         = (price * 1.18).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(children: [

        // ── Scrollable content ────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [

              // Image + buttons
              Stack(children: [
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: 300,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                      child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                      child: Icon(
                        _wishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: _wishlisted ? Colors.red : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 8),

              // Name + Price
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['name'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text('₹${p['price']}',
                        style: const TextStyle(fontSize: 24,
                            fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(width: 10),
                    Text('MRP ₹$mrp',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('18% OFF',
                          style: TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('Inclusive of all taxes',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(isAvailable ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isAvailable ? Colors.green.shade600 : Colors.red),
                    const SizedBox(width: 6),
                    Text(isAvailable ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                            color: isAvailable ? Colors.green.shade600 : Colors.red,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ]),
              ),

              const SizedBox(height: 8),

              // Delivery info
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Delivery Information',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _deliveryRow(Icons.local_shipping_outlined, Colors.blue,
                      'Free Delivery', 'Sabhi orders pe bilkul free!'),
                  const Divider(height: 20),
                  _deliveryRow(Icons.access_time_outlined, Colors.orange,
                      '30-45 min Delivery', 'Prayagraj ke andar fast delivery'),
                  const Divider(height: 20),
                  _deliveryRow(Icons.replay_outlined, Colors.purple,
                      'Easy Returns', '3 din ke andar return kar sakte ho'),
                  const Divider(height: 20),
                  _deliveryRow(Icons.verified_outlined, Colors.green,
                      'Fresh & Genuine', 'Quality guaranteed products'),
                ]),
              ),

              const SizedBox(height: 8),

              // Quantity
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  const Text('Quantity',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      GestureDetector(
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Icon(Icons.remove, size: 18,
                              color: _quantity > 1
                                  ? Colors.black87 : Colors.grey.shade300),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_quantity',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _quantity++),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: const Icon(Icons.add, size: 18,
                              color: Colors.black87),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 8),

              // Description
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Product Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(p['description'] ?? 'Yeh product fresh aur genuine hai.',
                      style: TextStyle(fontSize: 14,
                          color: Colors.grey.shade600, height: 1.6)),
                ]),
              ),

              const SizedBox(height: 8),

              // Ratings
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ratings & Reviews',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Column(children: [
                      Text(_ratingsLoaded ? _avgRating.toStringAsFixed(1) : '0.0',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800)),
                      Row(children: List.generate(5, (i) => Icon(
                          i < 4 ? Icons.star : Icons.star_half,
                          color: Colors.amber, size: 16))),
                      const SizedBox(height: 4),
                      Text('$_totalRatings ratings',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ]),
                    const SizedBox(width: 20),
                    Expanded(child: Column(children: [
                      _ratingBar(5, 0.65, '65%'),
                      _ratingBar(4, 0.20, '20%'),
                      _ratingBar(3, 0.08, '8%'),
                      _ratingBar(2, 0.04, '4%'),
                      _ratingBar(1, 0.03, '3%'),
                    ])),
                  ]),
                ]),
              ),

              const SizedBox(height: 20),
            ]),
          ),
        ),

        // ── Bottom Bar ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              Text('₹${_total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('$_quantity item${_quantity > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isAvailable && !_isLoading ? () async {
                  setState(() => _isLoading = true);
                  final ok = await ApiService.addToCart(
                      widget.product['id'], _quantity);
                  setState(() => _isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? '$_quantity item cart mein add! 🛒'
                          : 'Error aa gaya!'),
                      backgroundColor:
                          ok ? Colors.green.shade700 : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                    if (ok) Navigator.pop(context);
                  }
                } : null,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(_isLoading ? 'Adding...' : 'Add to Cart',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade50,
    child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
  );

  Widget _deliveryRow(IconData icon, Color color, String title, String sub) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ])),
      ]);

  Widget _ratingBar(int star, double val, String pct) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text('$star', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      const SizedBox(width: 4),
      const Icon(Icons.star, size: 10, color: Colors.amber),
      const SizedBox(width: 6),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            backgroundColor: Colors.grey.shade200,
            color: Colors.green.shade600,
            minHeight: 6,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(pct, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
    ]),
  );
}