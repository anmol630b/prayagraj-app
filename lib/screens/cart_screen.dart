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
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
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

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final success = await ApiService.placeOrder(_deliveryAddress);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment aur Order successful!'), backgroundColor: Colors.green),
      );
      _loadCart();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment fail ho gayi!'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _openRazorpay(String address) {
    _deliveryAddress = address;
    var options = {
      'key': 'rzp_test_SLkDH5I8tf4nZn',
      'amount': (_getTotal() * 100).toInt(),
      'name': 'Prayagraj Delivery',
      'description': 'Food Order',
      'prefill': {
        'contact': '9999999999',
        'email': 'test@test.com',
      }
    };
    _razorpay.open(options);
  }

  void _placeOrder() {
    showDialog(
      context: context,
      builder: (context) {
        final addressController = TextEditingController();
        return AlertDialog(
          title: const Text('Delivery Address'),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(hintText: 'Apna address likho'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openRazorpay(addressController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Pay Karo', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Cart khali hai!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return ListTile(
                            leading: const Icon(Icons.shopping_bag, color: Colors.green),
                            title: Text(item['product_name'] ?? 'Product'),
                            subtitle: Text('₹${item['product_price']} | Qty: ${item['quantity']}'),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Total: ₹${_getTotal().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _placeOrder,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Pay & Order',
                                  style: TextStyle(color: Colors.white, fontSize: 18)),
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