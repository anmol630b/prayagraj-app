import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isLoading = false;
  bool _isWishlisted = false;

  double get _totalPrice =>
      double.parse(widget.product['price'].toString()) * _quantity;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageUrl = p['image_url'];
    final isAvailable = p['is_available'] == true;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Image AppBar ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _isWishlisted = !_isWishlisted),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Icon(_isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: _isWishlisted ? Colors.red : Colors.grey.shade600, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),

          // ── Content ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Name + Price block ──────────────────────
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Availability badge
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: isAvailable ? Colors.green.shade300 : Colors.red.shade300),
                        ),
                        child: Text(isAvailable ? '✅ In Stock' : '❌ Out of Stock',
                            style: TextStyle(
                                color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      if (p['category_name'] != null)
                        Text(p['category_name'],
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ]),
                    const SizedBox(height: 10),

                    // Name
                    Text(p['name'],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
                    const SizedBox(height: 12),

                    // Price row
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₹${p['price']}',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                              color: Colors.green.shade700)),
                      const SizedBox(width: 10),
                      Text('₹${(double.parse(p['price'].toString()) * 1.2).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('17% OFF',
                            style: TextStyle(color: Colors.white,
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('Inclusive of all taxes',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ]),
                ),

                const SizedBox(height: 8),

                // ── Delivery info ───────────────────────────
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Delivery & Services',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _deliveryRow(Icons.local_shipping_outlined, Colors.blue,
                        'Free Delivery', 'Sabhi orders pe free delivery'),
                    const SizedBox(height: 10),
                    _deliveryRow(Icons.access_time_outlined, Colors.orange,
                        'Delivery in 30-45 min', 'Prayagraj ke andar'),
                    const SizedBox(height: 10),
                    _deliveryRow(Icons.replay_outlined, Colors.purple,
                        'Easy Returns', '3 din mein return kar sakte ho'),
                  ]),
                ),

                const SizedBox(height: 8),

                // ── Quantity ────────────────────────────────
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Text('Quantity',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        GestureDetector(
                          onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Icon(Icons.remove, size: 18,
                                color: _quantity > 1 ? Colors.green.shade700 : Colors.grey.shade300),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('$_quantity',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _quantity++),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Icon(Icons.add, size: 18, color: Colors.green.shade700),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 8),

                // ── Description ─────────────────────────────
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Product Description',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(p['description'] ?? 'Koi description nahi hai.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6)),
                  ]),
                ),

                const SizedBox(height: 8),

                // ── Ratings placeholder ─────────────────────
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Ratings & Reviews',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(children: [
                          Text('4.5', style: TextStyle(color: Colors.white,
                              fontSize: 28, fontWeight: FontWeight.bold)),
                          Text('★★★★★', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(children: [
                        _ratingBar(5, 0.7),
                        _ratingBar(4, 0.15),
                        _ratingBar(3, 0.08),
                        _ratingBar(2, 0.04),
                        _ratingBar(1, 0.03),
                      ])),
                    ]),
                  ]),
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom Bar ──────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total Amount', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            Text('₹${_totalPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: Colors.green.shade700)),
            Text('$_quantity item${_quantity > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isAvailable && !_isLoading ? () async {
                setState(() => _isLoading = true);
                final success = await ApiService.addToCart(widget.product['id'], _quantity);
                setState(() => _isLoading = false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(success ? '$_quantity item cart mein add! 🛒' : 'Error aa gaya!'),
                    ]),
                    backgroundColor: success ? Colors.green.shade700 : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                }
              } : null,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_shopping_cart, size: 20),
              label: Text(_isLoading ? 'Adding...' : 'Add to Cart',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.green.shade50,
    child: Icon(Icons.shopping_bag, size: 100, color: Colors.green.shade200),
  );

  Widget _deliveryRow(IconData icon, Color color, String title, String sub) =>
      Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ]),
      ]);

  Widget _ratingBar(int star, double fraction) => Padding(
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
            value: fraction,
            backgroundColor: Colors.grey.shade200,
            color: Colors.green.shade600,
            minHeight: 6,
          ),
        ),
      ),
    ]),
  );
}