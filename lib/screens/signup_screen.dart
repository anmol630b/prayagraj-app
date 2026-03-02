import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  const ProfileScreen({super.key, required this.username, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  int _getOrderCount(String status) {
    return _orders.where((o) => o['status'] == status).length;
  }

  double _getTotalSpent() {
    return _orders.fold(0, (sum, o) => sum + double.parse(o['total_price'].toString()));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout karo?'),
        content: const Text('Kya aap sach mein logout karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.green.shade700,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.username[0].toUpperCase(),
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.username,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard('Total Orders', '${_orders.length}', Icons.receipt_long, Colors.blue),
                            const SizedBox(width: 10),
                            _statCard('Delivered', '${_getOrderCount('delivered')}', Icons.done_all, Colors.green),
                            const SizedBox(width: 10),
                            _statCard('Pending', '${_getOrderCount('pending')}', Icons.access_time, Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.currency_rupee, color: Colors.green.shade700),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Spent', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  Text('₹${_getTotalSpent().toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Account Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _menuItem(Icons.person_outline, 'Profile Info', '${widget.username} • ${widget.email}', Colors.blue),
                        _menuItem(Icons.notifications_outlined, 'Notifications', 'On hai', Colors.orange),
                        _menuItem(Icons.help_outline, 'Help & Support', 'Koi problem? Batao', Colors.purple),
                        _menuItem(Icons.info_outline, 'App Version', 'v1.0.0', Colors.grey),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      ),
    );
  }
}