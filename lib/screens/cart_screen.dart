import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> with WidgetsBindingObserver {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  String _defaultAddress = '';
  String _deliveryAddress = '';

  String _signature = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadCart();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await ApiService.getSavedAddresses();
      final defaultAddr = addresses.firstWhere(
        (a) => a['is_default'] == true,
        orElse: () => addresses.isNotEmpty ? addresses[0] : null,
      );
      if (defaultAddr != null && mounted) {
        _defaultAddress = defaultAddr['address'];
      }
    } catch (e) {}
  }

  void loadCart() => _loadCart();

  void _loadCart() async {
    try {
      final items = await ApiService.getCart();
      if (mounted) setState(() { _cartItems = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _getTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += double.parse(item['product_price'].toString()) * item['quantity'];
    }
    return total;
  }

  void _updateQuantity(int index, int change) async {
    final item   = _cartItems[index];
    final newQty = item['quantity'] + change;
    setState(() {
      if (newQty <= 0) _cartItems.removeAt(index);
      else _cartItems[index]['quantity'] = newQty;
    });
    if (newQty <= 0) await ApiService.removeFromCart(item['id']);
    else await ApiService.updateCartQuantity(item['id'], newQty);
  }




  void _placeCODOrder(String address) async {
    setState(() => _isLoading = true);
    try {
      await ApiService.placeOrder(
        address: address,
        paymentMethod: 'cod',
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      loadCart();
      // Orders reload trigger karo
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() {});
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Order placed successfully! 🎉'),
        ]),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: \$e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
  void _placeOrder() async {
    await _loadDefaultAddress();
    final addressController = TextEditingController(text: _defaultAddress);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.location_on, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          Text('Enter your delivery address',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 16),

          TextField(
            controller: addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your full address...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_cartItems.length} items',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('₹${_getTotal().toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: Colors.green.shade700)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Delivery', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text('FREE', style: TextStyle(color: Colors.green.shade700,
                    fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter delivery address!'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                final addr = addressController.text.trim();
                Navigator.pop(ctx);
                Future.delayed(const Duration(milliseconds: 300), () {
                  _placeCODOrder(addr);
                });
              },
              icon: const Icon(Icons.payment, color: Colors.white),
              label: Text('Pay ₹${_getTotal().toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 17, color: Colors.white,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
  bool _orderPlaced = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(children: [

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              const Text('My Cart 🛒',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const Spacer(),
              if (_cartItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_cartItems.length} items',
                      style: TextStyle(color: Colors.green.shade700,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () { setState(() => _isLoading = true); _loadCart(); },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.refresh, color: Colors.grey.shade600, size: 20),
                ),
              ),
            ]),
          ),

          Container(height: 1, color: Colors.grey.shade200),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _cartItems.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 90, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Your cart is empty!',
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Text('Add products from Home',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cartItems.length,
                        itemBuilder: (_, index) {
                          final item      = _cartItems[index];
                          final itemTotal = double.parse(
                              item['product_price'].toString()) * item['quantity'];
                          final imageUrl  = item['product_image']; // ✅ ab aayega

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 70, height: 70,
                                    child: imageUrl != null && imageUrl.isNotEmpty
                                        ? Image.network(imageUrl, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _imagePlaceholder())
                                        : _imagePlaceholder(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Text(item['product_name'] ?? 'Product',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 14,
                                          color: Colors.black87),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('₹${item['product_price']} / piece',
                                      style: TextStyle(color: Colors.grey.shade400,
                                          fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text('₹${itemTotal.toStringAsFixed(0)}',
                                      style: TextStyle(color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold, fontSize: 15)),
                                ])),

                                const SizedBox(width: 8),

                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(children: [
                                    GestureDetector(
                                      onTap: () => _updateQuantity(index, -1),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          item['quantity'] <= 1
                                              ? Icons.delete_outline
                                              : Icons.remove,
                                          size: 18,
                                          color: item['quantity'] <= 1
                                              ? Colors.red.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text('${item['quantity']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                    GestureDetector(
                                      onTap: () => _updateQuantity(index, 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(Icons.add, size: 18,
                                            color: Colors.green.shade700),
                                      ),
                                    ),
                                  ]),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
          ),

          if (!_isLoading && _cartItems.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(children: [
                Container(height: 1, color: Colors.grey.shade100),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(children: [
                    _billRow('Item Total', '₹${_getTotal().toStringAsFixed(0)}', Colors.black87),
                    const SizedBox(height: 6),
                    _billRow('Delivery Charges', 'FREE', Colors.green.shade600),
                    const Divider(height: 16),
                    _billRow('Total Amount', '₹${_getTotal().toStringAsFixed(0)}',
                        Colors.black87, bold: true),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _placeOrder,
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: Text(
                        'Proceed to Pay  ₹${_getTotal().toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: Colors.grey.shade50,
    child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade300, size: 30),
  );

  Widget _billRow(String label, String value, Color valueColor, {bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
            color: Colors.grey.shade500, fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(
            color: valueColor, fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
      ]);
}