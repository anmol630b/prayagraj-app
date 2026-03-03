import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> _cartItems = [];
  bool _isLoading = true;
  late Razorpay _razorpay;
  String _deliveryAddress = '';

  @override
  void initState() {
    super.initState();
    _loadCart();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _loadCart() async {
    try {
      final items = await ApiService.getCart();
      setState(() { _cartItems = items; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
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
    final item = _cartItems[index];
    final newQty = item['quantity'] + change;
    if (newQty <= 0) {
      // Remove from cart
      await ApiService.removeFromCart(item['id']);
    } else {
      // Update quantity
      await ApiService.updateCartQuantity(item['id'], newQty);
    }
    _loadCart();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final success = await ApiService.placeOrder(_deliveryAddress);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Payment aur Order successful! 🎉'),
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadCart();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Payment fail ho gayi!'),
          ]),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _openRazorpay(String address) async {
    _deliveryAddress = address;
    // Razorpay key backend se lao
    final payment = await ApiService.createPayment(_getTotal().toInt());
    var options = {
      'key': payment['key'] ?? '',
      'amount': (_getTotal() * 100).toInt(),
      'order_id': payment['order_id'] ?? '',
      'name': 'Prayagraj Delivery',
      'description': 'Food Order',
      'prefill': {'contact': '9999999999', 'email': 'test@test.com'},
    };
    _razorpay.open(options);
  }

  void _placeOrder() {
    final addressController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Apna poora address likho...',
                prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (addressController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address daalo pehle!')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _openRazorpay(addressController.text.trim());
                },
                icon: const Icon(Icons.payment, color: Colors.white),
                label: Text('Pay ₹${_getTotal().toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Cart 🛒',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadCart();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 100, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Cart khali hai!',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('Kuch products add karo',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final itemTotal =
                              double.parse(item['product_price'].toString()) *
                                  item['quantity'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6)
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.shopping_bag,
                                      color: Colors.green.shade400),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['product_name'] ?? 'Product',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${item['product_price']}',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity +/- buttons
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _updateQuantity(index, -1),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.red.shade200),
                                        ),
                                        child: Icon(Icons.remove,
                                            size: 16,
                                            color: Colors.red.shade400),
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item['quantity']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _updateQuantity(index, 1),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.green.shade300),
                                        ),
                                        child: Icon(Icons.add,
                                            size: 16,
                                            color: Colors.green.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '₹${itemTotal.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, -4))
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_cartItems.length} items',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              Text(
                                'Total: ₹${_getTotal().toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _placeOrder,
                              icon: const Icon(Icons.payment,
                                  color: Colors.white),
                              label: const Text('Pay & Order karo',
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}