import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});
  @override
  State<OrderScreen> createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void loadOrders() => _loadOrders();

  void _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Confirmed':        return Colors.blue;
      case 'Delivered':        return Colors.green;
      case 'Cancelled':        return Colors.red;
      case 'Out for Delivery': return Colors.orange;
      default:                 return Colors.amber;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Confirmed':        return Icons.check_circle;
      case 'Delivered':        return Icons.done_all;
      case 'Cancelled':        return Icons.cancel;
      case 'Out for Delivery': return Icons.delivery_dining;
      default:                 return Icons.access_time;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Confirmed':        return 'Confirmed';
      case 'Delivered':        return 'Delivered';
      case 'Cancelled':        return 'Cancelled';
      case 'Out for Delivery': return 'On the Way';
      default:                 return 'Pending';
    }
  }

  void _showTracking(BuildContext screenCtx, dynamic order) {
    final steps       = ['Pending', 'Confirmed', 'Out for Delivery', 'Delivered'];
    final currentStep = steps.indexOf(order['status']);

    showModalBottomSheet(
      context: screenCtx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Handle
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          )),

          // Order header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long, color: Colors.green.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #${order['id']}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('₹${order['total_price']}',
                  style: TextStyle(color: Colors.green.shade700,
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(order['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _statusColor(order['status']).withOpacity(0.3)),
              ),
              child: Text(_statusLabel(order['status']),
                  style: TextStyle(color: _statusColor(order['status']),
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),

          const SizedBox(height: 12),

          // Address
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Icon(Icons.location_on, color: Colors.red.shade400, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(order['address'],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
            ]),
          ),

          const SizedBox(height: 24),

          // Tracking steps
          const Align(alignment: Alignment.centerLeft,
              child: Text('Order Tracking',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          const SizedBox(height: 16),

          Row(children: [
            _tStep(Icons.access_time,    'Pending',    currentStep >= 0, Colors.amber),
            _tLine(currentStep >= 1),
            _tStep(Icons.check_circle,   'Confirmed',  currentStep >= 1, Colors.blue),
            _tLine(currentStep >= 2),
            _tStep(Icons.delivery_dining,'On Way',     currentStep >= 2, Colors.orange),
            _tLine(currentStep >= 3),
            _tStep(Icons.done_all,       'Delivered',  currentStep >= 3, Colors.green),
          ]),

          const SizedBox(height: 20),

          // Cancel button
          if (order['status'] == 'Pending') ...[
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  final confirm = await showDialog<bool>(
                    context: screenCtx,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Cancel Order?'),
                      content: Text('Are you sure you want to cancel Order #${order['id']}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(screenCtx, false),
                          child: Text('No',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(screenCtx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: const Text('Yes, Cancel',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await ApiService.cancelOrder(order['id']);
                    if (mounted) {
                      ScaffoldMessenger.of(screenCtx).showSnackBar(SnackBar(
                        content: Text(ok
                            ? '✅ Order Cancelled!'
                            : '❌ Could not cancel, please try again'),
                        backgroundColor:
                            ok ? Colors.red.shade600 : Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                      if (ok) {
                        setState(() => _isLoading = true);
                        _loadOrders();
                      }
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel Order',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _tStep(IconData icon, String label, bool active, Color color) =>
      Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.15) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: active ? color : Colors.grey.shade400, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: active ? color : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ]);

  Widget _tLine(bool active) => Expanded(child: Container(
    height: 3,
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: active ? Colors.green : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(2),
    ),
  ));

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(children: [

          // ── Header ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              const Text('My Orders 📦',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const Spacer(),
              if (_orders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_orders.length} orders',
                      style: TextStyle(color: Colors.green.shade700,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () { setState(() => _isLoading = true); _loadOrders(); },
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

          // ── Body ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _orders.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 90, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No orders yet!',
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Text('Place your first order!',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                        ]))
                    : RefreshIndicator(
                        color: Colors.green,
                        onRefresh: () async => _loadOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (ctx, index) {
                            final order       = _orders[index];
                            final color       = _statusColor(order['status']);
                            final isPending   = order['status'] == 'Pending';

                            return GestureDetector(
                              onTap: () => _showTracking(ctx, order),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(children: [
                                    Row(children: [
                                      // Status icon
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(_statusIcon(order['status']),
                                            color: color, size: 22),
                                      ),
                                      const SizedBox(width: 12),

                                      // Order info
                                      Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                        Text('Order #${order['id']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text(order['address'],
                                            style: TextStyle(
                                                color: Colors.grey.shade400, fontSize: 12),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ])),

                                      // Price + status badge
                                      Column(crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                        Text('₹${order['total_price']}',
                                            style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(_statusLabel(order['status']),
                                              style: TextStyle(color: color,
                                                  fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                      ]),
                                    ]),

                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),

                                    Row(children: [
                                      if (isPending) ...[
                                        Icon(Icons.info_outline,
                                            size: 13, color: Colors.red.shade400),
                                        const SizedBox(width: 4),
                                        Text('You can cancel this order',
                                            style: TextStyle(
                                                color: Colors.red.shade400, fontSize: 12)),
                                      ] else ...[
                                        Icon(Icons.local_shipping_outlined,
                                            size: 13, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Text('Track your order',
                                            style: TextStyle(
                                                color: Colors.grey.shade400, fontSize: 12)),
                                      ],
                                      const Spacer(),
                                      Text('View Details',
                                          style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      Icon(Icons.arrow_forward_ios,
                                          size: 11, color: Colors.green.shade700),
                                    ]),
                                  ]),
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
}