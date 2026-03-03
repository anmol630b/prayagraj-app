import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  late TabController _tabController;

  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  bool _orderNotif    = true;
  bool _promoNotif    = false;
  bool _deliveryNotif = true;
  bool _locationAccess = true;
  bool _dataSharing   = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameCtrl  = TextEditingController(text: ApiService.username);
    _emailCtrl = TextEditingController(text: ApiService.email);
    _phoneCtrl = TextEditingController();
    _loadOrders();
    _loadPrefs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _orderNotif     = p.getBool('notif_order')      ?? true;
      _promoNotif     = p.getBool('notif_promo')      ?? false;
      _deliveryNotif  = p.getBool('notif_delivery')   ?? true;
      _locationAccess = p.getBool('privacy_location') ?? true;
      _dataSharing    = p.getBool('privacy_data')     ?? false;
      _phoneCtrl.text = p.getString('user_phone')     ?? '';
    });
  }

  void _savePref(String key, dynamic val) async {
    final p = await SharedPreferences.getInstance();
    if (val is bool) await p.setBool(key, val);
    if (val is String) await p.setString(key, val);
  }

  void _loadOrders() async {
    try {
      final orders = await ApiService.getOrders();
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _count(String s) => _orders.where((o) => o['status'] == s).length;
  double _totalSpent() => _orders.fold(
      0, (sum, o) => sum + double.parse(o['total_price'].toString()));

  void _saveProfile() async {
    _savePref('user_phone', _phoneCtrl.text);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 8),
        Text('Profile update ho gayi!'),
      ]),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$url open nahi hua'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _callPhone() => _launchUrl('tel:+919999999999');
  void _sendEmail() => _launchUrl('mailto:support@prayagrajdelivery.com?subject=Support Request');
  void _openWhatsApp() => _launchUrl('https://wa.me/919999999999?text=Hello, I need help with my order');

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHeader(Icons.notifications, 'Notifications', Colors.orange),
          const SizedBox(height: 20),
          _toggleRow(setBS, icon: Icons.receipt_long, color: Colors.blue,
              title: 'Order Updates', sub: 'Place, confirm, delivered',
              val: _orderNotif, onChanged: (v) {
                setBS(() => _orderNotif = v);
                setState(() => _orderNotif = v);
                _savePref('notif_order', v);
              }),
          _toggleRow(setBS, icon: Icons.local_offer, color: Colors.purple,
              title: 'Offers & Deals', sub: 'Discounts, special offers',
              val: _promoNotif, onChanged: (v) {
                setBS(() => _promoNotif = v);
                setState(() => _promoNotif = v);
                _savePref('notif_promo', v);
              }),
          _toggleRow(setBS, icon: Icons.delivery_dining, color: Colors.green,
              title: 'Delivery Alerts', sub: 'Agent pickup, on the way',
              val: _deliveryNotif, onChanged: (v) {
                setBS(() => _deliveryNotif = v);
                setState(() => _deliveryNotif = v);
                _savePref('notif_delivery', v);
              }),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }

  void _openPrivacy() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHeader(Icons.security, 'Privacy & Security', Colors.green),
          const SizedBox(height: 20),
          _toggleRow(setBS, icon: Icons.location_on, color: Colors.blue,
              title: 'Location Access', sub: 'Delivery ke liye zaroori',
              val: _locationAccess, onChanged: (v) {
                setBS(() => _locationAccess = v);
                setState(() => _locationAccess = v);
                _savePref('privacy_location', v);
              }),
          _toggleRow(setBS, icon: Icons.share, color: Colors.orange,
              title: 'Data Sharing', sub: 'Anonymous analytics',
              val: _dataSharing, onChanged: (v) {
                setBS(() => _dataSharing = v);
                setState(() => _dataSharing = v);
                _savePref('privacy_data', v);
              }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(children: [
              Icon(Icons.lock, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Aapka data encrypted hai. Kabhi bhi third party ko share nahi hoga.',
                style: TextStyle(color: Colors.green.shade800, fontSize: 12),
              )),
            ]),
          ),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }

  void _openChangePassword() {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    bool oldVisible  = false;
    bool newVisible  = false;
    bool confVisible = false;
    bool isLoading   = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bsCtx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHeader(Icons.lock_outline, 'Change Password', Colors.indigo),
          const SizedBox(height: 20),
          TextField(
            controller: oldCtrl,
            obscureText: !oldVisible,
            decoration: InputDecoration(
              labelText: 'Purana Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(oldVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setBS(() => oldVisible = !oldVisible),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtrl,
            obscureText: !newVisible,
            decoration: InputDecoration(
              labelText: 'Naya Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(newVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setBS(() => newVisible = !newVisible),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confCtrl,
            obscureText: !confVisible,
            decoration: InputDecoration(
              labelText: 'Password Confirm Karo',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(confVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setBS(() => confVisible = !confVisible),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty || confCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Saare fields bharein!'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                if (newCtrl.text != confCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Naya password match nahi kar raha!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Password kam se kam 6 characters ka hona chahiye!'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                setBS(() => isLoading = true);
                final result = await ApiService.changePassword(oldCtrl.text, newCtrl.text);
                setBS(() => isLoading = false);
                if (mounted) Navigator.pop(bsCtx);
                if (result.containsKey('message')) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['error'] ?? 'Kuch galat hua!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Password Change Karo',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      )),
    );
  }

  void _openHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sheetHeader(Icons.help, 'Help & Support', Colors.blue),
            const SizedBox(height: 20),
            GestureDetector(onTap: _callPhone,
                child: _contactTile(Icons.phone, '+91 9999999999', 'Call karo', Colors.green)),
            GestureDetector(onTap: _sendEmail,
                child: _contactTile(Icons.email, 'support@prayagrajdelivery.com', 'Email karo', Colors.blue)),
            GestureDetector(onTap: _openWhatsApp,
                child: _contactTile(Icons.chat, 'WhatsApp pe chat karo', 'Instant reply milega', Colors.green)),
            const SizedBox(height: 20),
            const Text('FAQs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            _faq('Order cancel kaise kare?',
                'Order place ke baad Orders tab se pending order tap karo aur Cancel button dabao.'),
            _faq('Refund kab milega?',
                '3-5 business days mein original payment method pe wapas aata hai.'),
            _faq('Delivery charge hai?', 'Abhi sabhi orders pe free delivery hai!'),
            _faq('Delivery time kitna hai?', 'Usually 30-45 minutes mein deliver ho jata hai.'),
            _faq('Password bhool gaya?', 'Profile mein Change Password option se naya password set karo.'),
          ]),
        ),
      ),
    );
  }

  void _openRateApp() {
    int stars = 0;
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Rate Our App ⭐',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Aapka feedback hamein improve karta hai!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setBS(() => stars = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(i < stars ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 42),
              ),
            )),
          ),
          if (stars > 0) ...[
            const SizedBox(height: 8),
            Text(['', 'Bahut bura 😞', 'Thoda theek 😐', 'Accha hai 🙂',
                'Bahut accha 😊', 'Ekdum best! 🎉'][stars],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: msgCtrl,
            maxLines: 2,
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
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: stars == 0 ? null : () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$stars ⭐ ke liye shukriya! 🎉'),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      )),
    );
  }

  void _showTracking(dynamic order) {
    final steps = ['pending', 'confirmed', 'out_for_delivery', 'delivered'];
    final step  = steps.indexOf(order['status']);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bsCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #${order['id']}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('₹${order['total_price']}',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.location_on, color: Colors.red.shade400, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(order['address'],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft,
              child: Text('Order Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          const SizedBox(height: 16),
          Row(children: [
            _tStep(Icons.access_time, 'Pending',    step >= 0, Colors.amber),
            _tLine(step >= 1),
            _tStep(Icons.check_circle, 'Confirmed', step >= 1, Colors.blue),
            _tLine(step >= 2),
            _tStep(Icons.delivery_dining, 'On Way', step >= 2, Colors.orange),
            _tLine(step >= 3),
            _tStep(Icons.done_all, 'Delivered',     step >= 3, Colors.green),
          ]),
          const SizedBox(height: 20),
          if (order['status'] == 'pending') ...[
            const Divider(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(bsCtx);
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
                      content: Text(ok ? '✅ Order cancel ho gaya!' : '❌ Cancel nahi hua'),
                      backgroundColor: ok ? Colors.red.shade600 : Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ));
                    if (ok) { setState(() => _isLoading = true); _loadOrders(); }
                  }
                }
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Order Cancel Karo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showAppInfo() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.info_outline, color: Colors.green),
        SizedBox(width: 8), Text('App Info'),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        _appInfoRow('App', 'Prayagraj Delivery'),
        _appInfoRow('Version', 'v1.0.0'),
        _appInfoRow('Developer', 'Anmol'),
        _appInfoRow('Backend', 'Django + Railway'),
      ]),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final username = ApiService.username;
    final email    = ApiService.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.green.shade700,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
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
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: _isEditing ? _editProfileUI() : _profileHeaderUI(username, email),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Order History')],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _overviewTab(username, email),
            _orderHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _profileHeaderUI(String username, String email) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 16),
      Stack(alignment: Alignment.bottomRight, children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                  color: Colors.green.shade700),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.green.shade400, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.verified, color: Colors.white, size: 12),
        ),
      ]),
      const SizedBox(height: 10),
      Text(username, style: const TextStyle(color: Colors.white, fontSize: 20,
          fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(email.isNotEmpty ? email : 'Prayagraj Delivery User',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]);
  }

  Widget _editProfileUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Edit Profile',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _editField(_nameCtrl, 'Name', Icons.person),
        const SizedBox(height: 8),
        _editField(_emailCtrl, 'Email', Icons.email),
        const SizedBox(height: 8),
        _editField(_phoneCtrl, 'Phone', Icons.phone),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity, height: 40,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save Changes',
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _editField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white70, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2)),
      ),
    );
  }

  Widget _overviewTab(String username, String email) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          _statCard('${_orders.length}', 'Total', Icons.receipt_long, Colors.blue.shade600),
          const SizedBox(width: 10),
          _statCard('${_count('delivered')}', 'Delivered', Icons.done_all, Colors.green.shade600),
          const SizedBox(width: 10),
          _statCard('${_count('pending')}', 'Pending', Icons.access_time, Colors.orange.shade600),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.25),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.currency_rupee, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Spent', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('₹${_totalSpent().toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            const Icon(Icons.trending_up, color: Colors.white60, size: 28),
          ]),
        ),
        const SizedBox(height: 20),
        _sectionLabel('Account Info'),
        const SizedBox(height: 10),
        _infoCard([
          _infoRow2(Icons.person, 'Username', username, Colors.blue),
          _divider(),
          _infoRow2(Icons.email, 'Email', email.isNotEmpty ? email : 'N/A', Colors.purple),
          _divider(),
          _infoRow2(Icons.phone, 'Phone',
              _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : 'Add karo', Colors.green),
        ]),
        const SizedBox(height: 20),
        _sectionLabel('Settings'),
        const SizedBox(height: 10),
        _settingsCard([
          _settingsTile(Icons.notifications_outlined, 'Notifications',
              _orderNotif || _deliveryNotif ? 'On' : 'Off', Colors.orange, _openNotifications),
          _divider(),
          _settingsTile(Icons.security, 'Privacy & Security',
              'Data settings', Colors.green, _openPrivacy),
          _divider(),
          _settingsTile(Icons.lock_outline, 'Change Password',
              'Password badlo', Colors.indigo, _openChangePassword),
          _divider(),
          _settingsTile(Icons.help_outline, 'Help & Support',
              'Call, Email, WhatsApp', Colors.blue, _openHelp),
          _divider(),
          _settingsTile(Icons.star_outline, 'Rate App',
              'Feedback do', Colors.amber, _openRateApp),
          _divider(),
          _settingsTile(Icons.info_outline, 'App Version',
              'v1.0.0', Colors.grey, _showAppInfo),
        ]),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.red, size: 18),
          label: const Text('Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _orderHistoryTab() {
    if (_isLoading) return const Center(
        child: CircularProgressIndicator(color: Colors.green));
    if (_orders.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('Koi order nahi hai!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Text('Pehla order place karo!', style: TextStyle(color: Colors.grey.shade500)),
      ]));
    }
    return RefreshIndicator(
      color: Colors.green,
      onRefresh: () async => _loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (_, i) {
          final order = _orders[i];
          final color = _statusColor(order['status']);
          return GestureDetector(
            onTap: () => _showTracking(order),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(_statusIcon(order['status']), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order #${order['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(order['address'],
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (order['status'] == 'pending')
                    Text('Tap karo cancel ke liye',
                        style: TextStyle(color: Colors.red.shade400, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${order['total_price']}',
                      style: TextStyle(color: Colors.green.shade700,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(order['status'],
                        style: TextStyle(color: color, fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':        return Colors.blue;
      case 'delivered':        return Colors.green;
      case 'cancelled':        return Colors.red;
      case 'out_for_delivery': return Colors.orange;
      default:                 return Colors.amber;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'confirmed':        return Icons.check_circle;
      case 'delivered':        return Icons.done_all;
      case 'cancelled':        return Icons.cancel;
      case 'out_for_delivery': return Icons.delivery_dining;
      default:                 return Icons.access_time;
    }
  }

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16);

  Widget _infoCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
    child: Column(children: children),
  );

  Widget _settingsCard(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
    child: Column(children: children),
  );

  Widget _infoRow2(IconData icon, String label, String val, Color color) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
    title: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
    subtitle: Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
    dense: true,
  );

  Widget _settingsTile(IconData icon, String title, String sub, Color color, VoidCallback onTap) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(sub, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
    trailing: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade300),
    dense: true,
  );

  Widget _statCard(String val, String label, IconData icon, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _sheetHeader(IconData icon, String title, Color color) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color),
    ),
    const SizedBox(width: 12),
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  ]);

  Widget _toggleRow(StateSetter setBS, {
    required IconData icon, required Color color,
    required String title, required String sub,
    required bool val, required ValueChanged<bool> onChanged,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ])),
      Switch(value: val, activeColor: Colors.green, onChanged: onChanged),
    ]),
  );

  Widget _contactTile(IconData icon, String title, String sub, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ])),
      Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
    ]),
  );

  Widget _faq(String q, String a) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      children: [Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(a, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      )],
    ),
  );

  Widget _tStep(IconData icon, String label, bool active, Color color) => Column(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: active ? color : Colors.grey.shade400, size: 20),
    ),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(color: active ? color : Colors.grey.shade400,
        fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
  ]);

  Widget _tLine(bool active) => Expanded(child: Container(
    height: 3, margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: active ? Colors.green : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(2),
    ),
  ));

  Widget _appInfoRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text('$label: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}