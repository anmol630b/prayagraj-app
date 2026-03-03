import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  // Notification toggles
  bool _orderNotif = true;
  bool _promoNotif = false;
  bool _deliveryNotif = true;

  // Privacy toggles
  bool _locationAccess = true;
  bool _dataSharing = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadPrefs();
  }

  void _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotif   = prefs.getBool('notif_order') ?? true;
      _promoNotif   = prefs.getBool('notif_promo') ?? false;
      _deliveryNotif = prefs.getBool('notif_delivery') ?? true;
      _locationAccess = prefs.getBool('privacy_location') ?? true;
      _dataSharing   = prefs.getBool('privacy_data') ?? false;
    });
  }

  void _savePref(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  void _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _getOrderCount(String status) =>
      _orders.where((o) => o['status'] == status).length;

  double _getTotalSpent() =>
      _orders.fold(0, (sum, o) => sum + double.parse(o['total_price'].toString()));

  // ── Logout ──────────────────────────────────────────────
  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8),
          Text('Logout karo?'),
        ]),
        content: const Text('Kya aap sach mein logout karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.clearSession();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Notifications Bottom Sheet ───────────────────────────
  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.notifications, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                const Text('Notification Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              _toggleTile(
                ctx, setBS,
                icon: Icons.receipt_long,
                color: Colors.blue,
                title: 'Order Updates',
                subtitle: 'Order place, confirm, delivered',
                value: _orderNotif,
                onChanged: (v) {
                  setBS(() => _orderNotif = v);
                  setState(() => _orderNotif = v);
                  _savePref('notif_order', v);
                },
              ),
              _toggleTile(
                ctx, setBS,
                icon: Icons.local_offer,
                color: Colors.purple,
                title: 'Offers & Promotions',
                subtitle: 'Deals, discounts, special offers',
                value: _promoNotif,
                onChanged: (v) {
                  setBS(() => _promoNotif = v);
                  setState(() => _promoNotif = v);
                  _savePref('notif_promo', v);
                },
              ),
              _toggleTile(
                ctx, setBS,
                icon: Icons.delivery_dining,
                color: Colors.green,
                title: 'Delivery Alerts',
                subtitle: 'Agent ne pickup kiya, raste mein hai',
                value: _deliveryNotif,
                onChanged: (v) {
                  setBS(() => _deliveryNotif = v);
                  setState(() => _deliveryNotif = v);
                  _savePref('notif_delivery', v);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Privacy Bottom Sheet ─────────────────────────────────
  void _openPrivacy() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.security, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                const Text('Privacy & Security',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              _toggleTile(
                ctx, setBS,
                icon: Icons.location_on,
                color: Colors.blue,
                title: 'Location Access',
                subtitle: 'Delivery ke liye location use hogi',
                value: _locationAccess,
                onChanged: (v) {
                  setBS(() => _locationAccess = v);
                  setState(() => _locationAccess = v);
                  _savePref('privacy_location', v);
                },
              ),
              _toggleTile(
                ctx, setBS,
                icon: Icons.share,
                color: Colors.orange,
                title: 'Data Sharing',
                subtitle: 'Analytics ke liye anonymous data',
                value: _dataSharing,
                onChanged: (v) {
                  setBS(() => _dataSharing = v);
                  setState(() => _dataSharing = v);
                  _savePref('privacy_data', v);
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.lock, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aapka data encrypted hai aur kabhi bhi third party ko nahi becha jayega.',
                      style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Help & Support Bottom Sheet ──────────────────────────
  void _openHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.help, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              const Text('Help & Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            _helpTile(Icons.phone, 'Call Us', '+91 9999999999', Colors.green),
            _helpTile(Icons.email, 'Email Us', 'support@prayagrajdelivery.com', Colors.blue),
            _helpTile(Icons.chat_bubble_outline, 'WhatsApp', 'Chat on WhatsApp', Colors.green),
            const SizedBox(height: 16),
            const Text('FAQs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _faqTile('Order cancel kaise kare?',
                'Order place hone ke 5 minute ke andar cancel kar sakte hain Orders tab se.'),
            _faqTile('Refund kab milega?',
                'Payment 3-5 business days mein wapas aa jayegi original payment method pe.'),
            _faqTile('Delivery charge kitna hai?',
                'Abhi free delivery hai sabhi orders pe!'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Rate App Bottom Sheet ────────────────────────────────
  void _openRateApp() {
    int selectedStars = 0;
    final msgController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate Our App ⭐',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Aapka feedback hamein behtar banata hai!',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setBS(() => selectedStars = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < selectedStars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: msgController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Koi suggestion? (optional)',
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
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedStars == 0 ? null : () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$selectedStars ⭐ ke liye shukriya! 🎉'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Review',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change Password Bottom Sheet ─────────────────────────
  void _openChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _passField(oldCtrl, 'Current Password', obscure,
                  () => setBS(() => obscure = !obscure)),
              const SizedBox(height: 12),
              _passField(newCtrl, 'New Password', obscure, null),
              const SizedBox(height: 12),
              _passField(confirmCtrl, 'Confirm New Password', obscure, null),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (newCtrl.text != confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Passwords match nahi kar rahe!')));
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Password change ho gaya ✅'),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Update Password',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Version Dialog ───────────────────────────────────
  void _openAppInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.info_outline, color: Colors.green),
          SizedBox(width: 8),
          Text('App Info'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('App Name', 'Prayagraj Delivery'),
            _infoRow('Version', 'v1.0.0'),
            _infoRow('Build', '2026.03.03'),
            _infoRow('Developer', 'Anmol'),
            _infoRow('Backend', 'Django + Railway'),
            _infoRow('Storage', 'Cloudinary'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final username = ApiService.username;
    final email    = ApiService.email;

    // Notification subtitle dynamically
    final notifOn = _orderNotif || _deliveryNotif || _promoNotif;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: Colors.green.shade700,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade900, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white,
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.verified, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(username,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(email.isNotEmpty ? email : 'Prayagraj Delivery User',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
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

          // ── Body ────────────────────────────────────────
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Colors.green)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Stats row
                        Row(children: [
                          _statCard('${_orders.length}', 'Total', Icons.receipt_long, Colors.blue.shade600),
                          const SizedBox(width: 10),
                          _statCard('${_getOrderCount('delivered')}', 'Delivered', Icons.done_all, Colors.green.shade600),
                          const SizedBox(width: 10),
                          _statCard('${_getOrderCount('pending')}', 'Pending', Icons.access_time, Colors.orange.shade600),
                        ]),
                        const SizedBox(height: 12),

                        // Total spent card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade700, Colors.green.shade500],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.green.withOpacity(0.3),
                                  blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.currency_rupee, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Total Spent',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text('₹${_getTotalSpent().toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            ]),
                            const Spacer(),
                            const Icon(Icons.trending_up, color: Colors.white70, size: 32),
                          ]),
                        ),
                        const SizedBox(height: 20),

                        // Account Info
                        _sectionTitle('Account Info'),
                        const SizedBox(height: 10),
                        _infoTile(Icons.person, 'Username', username, Colors.blue),
                        _infoTile(Icons.email, 'Email',
                            email.isNotEmpty ? email : 'N/A', Colors.purple),
                        GestureDetector(
                          onTap: _openChangePassword,
                          child: _infoTile(Icons.lock_outline, 'Password', '••••••••', Colors.red),
                        ),
                        const SizedBox(height: 20),

                        // Settings
                        _sectionTitle('Settings'),
                        const SizedBox(height: 10),

                        _menuTile(
                          Icons.notifications_outlined,
                          'Notifications',
                          notifOn ? 'Kuch notifications on hain' : 'Sabhi notifications off hain',
                          Colors.orange,
                          onTap: _openNotifications,
                          trailing: Switch(
                            value: notifOn,
                            activeColor: Colors.green,
                            onChanged: (v) {
                              setState(() {
                                _orderNotif = v;
                                _deliveryNotif = v;
                                _promoNotif = v;
                              });
                              _savePref('notif_order', v);
                              _savePref('notif_delivery', v);
                              _savePref('notif_promo', v);
                            },
                          ),
                        ),

                        _menuTile(
                          Icons.security,
                          'Privacy & Security',
                          'Data aur location settings',
                          Colors.green,
                          onTap: _openPrivacy,
                        ),

                        _menuTile(
                          Icons.help_outline,
                          'Help & Support',
                          'FAQs, call, email',
                          Colors.blue,
                          onTap: _openHelp,
                        ),

                        _menuTile(
                          Icons.star_outline,
                          'Rate App',
                          'Hamara app rate karo ⭐',
                          Colors.amber,
                          onTap: _openRateApp,
                        ),

                        _menuTile(
                          Icons.info_outline,
                          'App Version',
                          'v1.0.0 — Latest',
                          Colors.grey,
                          onTap: _openAppInfo,
                        ),

                        const SizedBox(height: 20),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text('Logout',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HELPER WIDGETS
  // ═══════════════════════════════════════════════════════

  Widget _sectionTitle(String title) =>
      Text(title, style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const Spacer(),
        Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey.shade300),
      ]),
    );
  }

  Widget _menuTile(IconData icon, String title, String subtitle, Color color,
      {required VoidCallback onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: trailing ??
            Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _toggleTile(BuildContext ctx, StateSetter setBS, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ])),
        Switch(value: value, activeColor: Colors.green, onChanged: onChanged),
      ]),
    );
  }

  Widget _helpTile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _faqTile(String question, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(answer,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _passField(
      TextEditingController ctrl, String hint, bool obscure, VoidCallback? toggleObscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: toggleObscure)
            : null,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$label: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}