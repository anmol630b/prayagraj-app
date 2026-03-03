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
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'out_for_delivery': return Colors.orange;
      default: return Colors.amber;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle;
      case 'delivered': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      case 'out_for_delivery': return Icons.delivery_dining;
      default: return Icons.access_time;
    }
  }

  void _showTracking(BuildContext context, dynamic order) {
    final status = order['status'];
    final steps = ['pending', 'confirmed', 'out_for_delivery', 'delivered'];
    final currentStep = steps.indexOf(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Order #${order['id']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${order['total_price']}',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
              ]),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(Icons.location_on, color: Colors.red.shade400, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(order['address'],
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('Order Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(children: [
              _trackingStep(Icons.access_time, 'Pending',   currentStep >= 0, Colors.amber),
              _trackingLine(currentStep >= 1),
              _trackingStep(Icons.check_circle, 'Confirmed', currentStep >= 1, Colors.blue),
              _trackingLine(currentStep >= 2),
              _trackingStep(Icons.delivery_dining, 'On Way', currentStep >= 2, Colors.orange),
              _trackingLine(currentStep >= 3),
              _trackingStep(Icons.done_all, 'Delivered',    currentStep >= 3, Colors.green),
            ]),
            const SizedBox(height: 20),

            // Cancel button — sirf pending orders pe dikhega
            if (status == 'pending') ...[
              const Divider(),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  // Confirm dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Order Cancel Karo?'),
                      content: Text('Order #${order['id']} cancel karna chahte ho?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Nahi'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Haan, Cancel Karo',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await ApiService.cancelOrder(order['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? '✅ Order cancel ho gaya!'
                            : '❌ Cancel nahi hua, dobara try karo'),
                        backgroundColor: ok ? Colors.red.shade600 : Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ));
                      if (ok) {
                        setState(() => _isLoading = true);
                        _loadOrders();
                      }
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Order Cancel Karo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _trackingStep(IconData icon, String label, bool isActive, Color color) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isActive ? color : Colors.grey.shade400, size: 22),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
          color: isActive ? color : Colors.grey.shade400,
          fontSize: 10,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  Widget _trackingLine(bool isActive) {
    return Expanded(child: Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My Orders 📦',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadOrders();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _orders.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 100, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('Koi order nahi hai!',
                        style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('Pehla order place karo!',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ))
              : RefreshIndicator(
                  color: Colors.green,
                  onRefresh: () async => _loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final statusColor = _getStatusColor(order['status']);
                      return GestureDetector(
                        onTap: () => _showTracking(context, order),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8)],
                          ),
                          child: Column(children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getStatusIcon(order['status']),
                                    color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Order #${order['id']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(order['address'],
                                      style: TextStyle(
                                          color: Colors.grey.shade500, fontSize: 12),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              )),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('₹${order['total_price']}',
                                    style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(order['status'],
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ]),
                            const SizedBox(height: 10),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              if (order['status'] == 'pending')
                                Text('Cancel available',
                                    style: TextStyle(
                                        color: Colors.red.shade400,
                                        fontSize: 11)),
                              const Spacer(),
                              Text('Track karo →',
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}