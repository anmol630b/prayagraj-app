import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showTracking(BuildContext context, dynamic order) {
    final status = order['status'];
    final steps = ['pending', 'confirmed', 'delivered'];
    final currentStep = steps.indexOf(status);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${order['id']} Tracking',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Address: ${order['address']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _trackingStep(Icons.access_time, 'Pending', currentStep >= 0, Colors.orange),
                _trackingLine(currentStep >= 1),
                _trackingStep(Icons.check_circle, 'Confirmed', currentStep >= 1, Colors.blue),
                _trackingLine(currentStep >= 2),
                _trackingStep(Icons.delivery_dining, 'Delivered', currentStep >= 2, Colors.green),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _trackingStep(IconData icon, String label, bool isActive, Color color) {
    return Column(
      children: [
        Icon(icon, color: isActive ? color : Colors.grey, size: 36),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isActive ? color : Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _trackingLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        color: isActive ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Koi order nahi hai!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.receipt, color: Colors.green),
                        title: Text('Order #${order['id']}'),
                        subtitle: Text('Address: ${order['address']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('₹${order['total_price']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order['status']),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(order['status'],
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                        onTap: () => _showTracking(context, order),
                      ),
                    );
                  },
                ),
    );
  }
}