import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'addresses_screen.dart';
import 'wishlist_screen.dart';
import 'chat_screen.dart';
import 'order_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _username = '';
  String _email = '';
  String _phone = '';
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _loadProfile() async {
    setState(() {
      _username = ApiService.username;
      _email = ApiService.email;
    });
    try {
      final data = await ApiService.getProfile();
      if (mounted) setState(() {
        _phone = data['phone'] ?? '';
        _email = data['email'] ?? _email;
        _phoneCtrl.text = _phone;
        _emailCtrl.text = _email;
        _nameCtrl.text = _username;
      });
    } catch (e) {}
  }

  void _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            ApiService.clearSession();
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false);
          },
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _changePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _pwField(oldCtrl, 'Current Password'),
          const SizedBox(height: 12),
          _pwField(newCtrl, 'New Password'),
          const SizedBox(height: 12),
          _pwField(confCtrl, 'Confirm New Password'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (newCtrl.text != confCtrl.text) {
                  _snack('Passwords do not match!', Colors.red); return;
                }
                final result = await ApiService.changePassword(
                    oldCtrl.text, newCtrl.text);
                if (!mounted) return;
                Navigator.pop(ctx);
                final ok = !result.containsKey('error');
                _snack(ok ? 'Password changed!' : 'Incorrect current password!',
                    ok ? Colors.green : Colors.red);
              },
              child: const Text('Change Password',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  String _statusText(String s) {
    switch (s) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'out_for_delivery': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green.shade700,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.person, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(_username,
                          style: const TextStyle(fontSize: 20,
                              fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(_email,
                          style: TextStyle(color: Colors.white.withOpacity(0.8),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Account'),
                Tab(text: 'Orders'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _accountTab(),
            _ordersTab(),
          ],
        ),
      ),
    );
  }

  Widget _accountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // Quick Actions
        Row(children: [
          _quickAction(Icons.favorite_outline, 'Wishlist', Colors.red, () =>
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const WishlistScreen()))),
          const SizedBox(width: 12),
          _quickAction(Icons.location_on_outlined, 'Addresses', Colors.blue, () =>
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AddressesScreen()))),
          const SizedBox(width: 12),
          _quickAction(Icons.chat_outlined, 'Support', Colors.green, () =>
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ChatScreen()))),
        ]),

        const SizedBox(height: 16),

        // Profile Info
        _sectionCard('Personal Info', [
          _infoTile(Icons.person_outline, 'Username', _username, Colors.green),
          const Divider(height: 1),
          _infoTile(Icons.email_outlined, 'Email', _email.isEmpty ? 'Not set' : _email, Colors.blue),
          const Divider(height: 1),
          GestureDetector(
          onTap: _editPhone,
          child: _infoTile(Icons.phone_outlined, 'Phone',
              _phone.isEmpty ? 'Tap to add' : _phone, Colors.orange),
        ),
        ]),

        const SizedBox(height: 16),

        // Settings
        _sectionCard('Settings', [
          _menuTile(Icons.lock_outline, 'Change Password', Colors.purple, _changePassword),
          const Divider(height: 1),
          _menuTile(Icons.star_outline, 'Rate App', Colors.amber, _rateApp),
          const Divider(height: 1),
          _menuTile(Icons.help_outline, 'Help & Support', Colors.teal, _openHelp),
          const Divider(height: 1),
          _menuTile(Icons.logout, 'Logout', Colors.red, _logout),
        ]),

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _ordersTab() {
    if (_isLoading) return const Center(
        child: CircularProgressIndicator(color: Colors.green));
    if (_orders.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No orders yet!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Place your first order',
            style: TextStyle(color: Colors.grey.shade400)),
      ],
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (_, i) {
        final order = _orders[i];
        final status = order['status'] ?? 'pending';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  color: _statusColor(status)),
            ),
            title: Text('Order #${order['id']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₹${order['total_price']}',
                style: TextStyle(color: Colors.green.shade700,
                    fontWeight: FontWeight.w600)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusText(status),
                      style: TextStyle(color: _statusColor(status),
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text('View Details',
                    style: TextStyle(color: Colors.green.shade700,
                        fontSize: 11)),
              ],
            ),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    OrderDetailScreen(order: order))),
          ),
        );
      },
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold,
              color: Colors.black87)),
        ),
        ...children,
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _infoTile(IconData icon, String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              color: Colors.grey.shade500, fontSize: 11)),
          Text(val, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ]),
    );
  }

  Widget _menuTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14, color: Colors.grey.shade400),
    );
  }

  void _editPhone() {
    final ctrl = TextEditingController(text: _phone);
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Phone Number',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: 'Enter phone number',
          prefixIcon: Icon(Icons.phone, color: Colors.grey.shade400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700, elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () async {
            await ApiService.updateProfile(phone: ctrl.text.trim());
            if (mounted) setState(() => _phone = ctrl.text.trim());
            Navigator.pop(context);
            _snack('Phone number updated!', Colors.green);
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _rateApp() {
    int _selectedRating = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.amber, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Rate Our App', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('How was your experience?',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setDialogState(() => _selectedRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedRating == 0 ? 'Tap to rate' :
              _selectedRating == 1 ? 'Poor 😞' :
              _selectedRating == 2 ? 'Fair 😐' :
              _selectedRating == 3 ? 'Good 🙂' :
              _selectedRating == 4 ? 'Great 😊' : 'Excellent! 🤩',
              style: TextStyle(
                color: _selectedRating >= 4 ? Colors.green.shade700 : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _selectedRating == 0 ? null : () {
                  Navigator.pop(ctx);
                  _snack('Thanks for rating us $_selectedRating ⭐!', Colors.amber.shade700);
                },
                child: const Text('Submit Rating',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _openHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Help & Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _faq('How to cancel order?',
              'Go to Orders tab, tap on pending order and press Cancel.'),
          _faq('When will I get refund?',
              'Refund will be processed in 3-5 business days.'),
          _faq('Delivery charge?', 'Free delivery on all orders!'),
          _faq('Delivery time?', 'Delivered in 30-45 minutes.'),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _faq(String q, String a) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14)),
      children: [Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(a, style: TextStyle(color: Colors.grey.shade600)),
      )],
    );
  }

  Widget _pwField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade600, width: 1.5)),
        labelStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
