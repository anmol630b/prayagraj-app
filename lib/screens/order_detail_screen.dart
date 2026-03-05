import 'package:flutter/material.dart';
import 'order_tracking_screen.dart';
import '../services/api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final dynamic order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<dynamic> _trackingSteps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  void _loadTracking() async {
    try {
      final data = await ApiService.getOrderTracking(widget.order['id']);
      if (mounted) setState(() { _trackingSteps = data is List ? data : []; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'out_for_delivery': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order['items'] as List? ?? [];
    final status = order['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text('Order #${order['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Order Status', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusText(status),
                      style: TextStyle(color: _statusColor(status),
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 16),
              // Progress steps
              Row(children: [
                _step('Placed', ['pending', 'confirmed', 'out_for_delivery', 'delivered'].contains(status)),
                _line(['confirmed', 'out_for_delivery', 'delivered'].contains(status)),
                _step('Confirmed', ['confirmed', 'out_for_delivery', 'delivered'].contains(status)),
                _line(['out_for_delivery', 'delivered'].contains(status)),
                _step('On Way', ['out_for_delivery', 'delivered'].contains(status)),
                _line(['delivered'].contains(status)),
                _step('Delivered', status == 'delivered'),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // Items Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Items Ordered', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Text('No items found', style: TextStyle(color: Colors.grey.shade400))
              else
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.shopping_bag_outlined,
                          color: Colors.green.shade700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['product_name'] ?? 'Product',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Qty: ${item['quantity']}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    )),
                    Text('₹${item['price']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                )).toList(),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('₹${order['total_price']}',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 16, color: Colors.green.shade700)),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // Address Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Delivery Address', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.location_on_outlined, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(order['address'] ?? 'N/A',
                    style: TextStyle(color: Colors.grey.shade600))),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          // Order Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Order Info', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _infoRow('Order ID', '#${order['id']}'),
              _infoRow('Payment', 'Online'),
              _infoRow('Delivery', 'FREE'),
              _infoRow('Date', order['created_at']?.toString().substring(0, 10) ?? 'N/A'),
            ]),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _step(String label, bool active) {
    return Column(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: active ? Colors.green.shade700 : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(active ? Icons.check : Icons.circle,
            size: 14, color: active ? Colors.white : Colors.grey.shade400),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
          fontSize: 9, color: active ? Colors.green.shade700 : Colors.grey.shade400,
          fontWeight: active ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  Widget _line(bool active) {
    return Expanded(child: Container(
      height: 2, margin: const EdgeInsets.only(bottom: 16),
      color: active ? Colors.green.shade700 : Colors.grey.shade200,
    ));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
