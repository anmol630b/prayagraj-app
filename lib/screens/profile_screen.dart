import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'addresses_screen.dart';

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
  bool _orderNotif = true, _promoNotif = false, _deliveryNotif = true;
  bool _locationAccess = true, _dataSharing = false;

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
      0.0, (sum, o) => sum + double.parse(o['total_price'].toString()));

  void _saveProfile() async {
    _savePref('user_phone', _phoneCtrl.text);
    setState(() => _isEditing = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Profile update ho gayi! ✅'),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _logout() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Icon(Icons.logout, color: Colors.red),
        SizedBox(width: 8),
        Text('Logout?'),
      ]),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
        ElevatedButton(
          onPressed: () async {
            await ApiService.clearSession();
            if (context.mounted) Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final username = ApiService.username;
    final email    = ApiService.email;
    final isDark   = MyApp.of(context)?.isDark ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(children: [

        // ── Green Header ────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade900, Colors.green.shade600],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [

              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(children: [
                  const Text('Profile', style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined,
                        color: Colors.white),
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                  ),
                ]),
              ),

              // Avatar + name
              if (!_isEditing) ...[
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                        color: Colors.green.shade700),
                  ),
                ),
                const SizedBox(height: 10),
                Text(username, style: const TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email.isNotEmpty ? email : 'Prayagraj Delivery User',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                const SizedBox(height: 16),

                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      _headerStat('${_orders.length}', 'Orders'),
                      _statDivider(),
                      _headerStat('${_count('delivered')}', 'Delivered'),
                      _statDivider(),
                      _headerStat('${_count('pending')}', 'Pending'),
                      _statDivider(),
                      _headerStat('₹${_totalSpent().toStringAsFixed(0)}', 'Spent'),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Edit form
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(children: [
                    _editField(_nameCtrl, 'Name', Icons.person_outline),
                    const SizedBox(height: 10),
                    _editField(_emailCtrl, 'Email', Icons.email_outlined),
                    const SizedBox(height: 10),
                    _editField(_phoneCtrl, 'Phone', Icons.phone_outlined),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, height: 42,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Save Changes',
                            style: TextStyle(color: Colors.green.shade700,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ),
              ],

              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [Tab(text: 'Overview'), Tab(text: 'Order History')],
              ),
            ]),
          ),
        ),

        // ── Tab content ─────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _overviewTab(username, email, isDark),
              _orderHistoryTab(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _headerStat(String val, String label) => Expanded(
    child: Column(children: [
      Text(val, style: const TextStyle(color: Colors.white,
          fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
          color: Colors.white.withOpacity(0.7), fontSize: 11)),
    ]),
  );

  Widget _statDivider() => Container(
    width: 1, height: 28,
    color: Colors.white.withOpacity(0.25),
  );

  Widget _editField(TextEditingController ctrl, String hint, IconData icon) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: Colors.white70, size: 18),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2)),
        ),
      );

  Widget _overviewTab(String username, String email, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // Total spent card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.currency_rupee, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Spent', style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 13)),
              Text('₹${_totalSpent().toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 28, fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 22),
              const SizedBox(height: 4),
              Text('${_orders.length} orders',
                  style: TextStyle(color: Colors.white.withOpacity(0.7),
                      fontSize: 12)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // Account Info
        _sectionTitle('Account Info'),
        const SizedBox(height: 8),
        _card([
          _infoTile(Icons.person_outline, 'Username', username, Colors.blue),
          _divider(),
          _infoTile(Icons.email_outlined, 'Email',
              email.isNotEmpty ? email : 'N/A', Colors.purple),
          _divider(),
          _infoTile(Icons.phone_outlined, 'Phone',
              _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : 'Add',
              Colors.green),
        ]),

        const SizedBox(height: 20),

        _sectionTitle('Settings'),
        const SizedBox(height: 8),

        _card([
          // Dark mode
          _switchTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            color: Colors.deepPurple,
            title: 'Dark Mode',
            sub: isDark ? 'On' : 'Off',
            value: isDark,
            onChanged: (v) {
              MyApp.of(context)?.toggleTheme(v);
              setState(() {});
            },
          ),
          _divider(),
          _settingTile(Icons.notifications_outlined, 'Notifications',
              _orderNotif || _deliveryNotif ? 'On' : 'Off',
              Colors.orange, _openNotifications),
          _divider(),
          _settingTile(Icons.security, 'Privacy & Security',
              'Data settings', Colors.teal, _openPrivacy),
          _divider(),
          _settingTile(Icons.lock_outline, 'Change Password',
              'Password badlo', Colors.indigo, _openChangePassword),
          _divider(),
          _settingTile(Icons.location_on_outlined, 'Saved Addresses',
              'Manage your addresses', Colors.orange, () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddressesScreen()))),
          _divider(),
          _settingTile(Icons.chat_outlined, 'Chat Support',
              'Talk to support', Colors.green, () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()))),
          _divider(),
          _settingTile(Icons.help_outline, 'Help & Support',
              'Call, Email, WhatsApp', Colors.blue, _openHelp),
          _divider(),
          _settingTile(Icons.star_outline, 'Rate App',
              'Feedback do', Colors.amber, _openRateApp),
          _divider(),
          _settingTile(Icons.info_outline, 'App Version', 'v1.0.0',
              Colors.grey, () => showDialog(context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('App Info'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    _infoRow2('App', 'Prayagraj Delivery'),
                    _infoRow2('Version', 'v1.0.0'),
                    _infoRow2('Developer', 'Anmol'),
                    _infoRow2('Backend', 'Django + Railway'),
                  ]),
                  actions: [ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  )],
                ))),
        ]),

        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.red, size: 18),
          label: const Text('Logout', style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.red.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _orderHistoryTab() {
    if (_isLoading) return const Center(
        child: CircularProgressIndicator(color: Colors.green));
    if (_orders.isEmpty) return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      const Text('No orders yet!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text('Place your first order!',
          style: TextStyle(color: Colors.grey.shade400)),
    ]));

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: () async => _loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (_, i) {
          final order = _orders[i];
          final color = _sColor(order['status']);
          return GestureDetector(
            onTap: () => _showTracking(order),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(_sIcon(order['status']), color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Order #${order['id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(order['address'],
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₹${order['total_price']}',
                          style: TextStyle(color: Colors.green.shade700,
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_sLabel(order['status']),
                            style: TextStyle(color: color, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ]),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (order['status'] == 'pending') ...[
                      Icon(Icons.cancel_outlined, size: 12,
                          color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text('Cancel available',
                          style: TextStyle(color: Colors.red.shade400, fontSize: 11)),
                    ] else ...[
                      Icon(Icons.local_shipping_outlined, size: 12,
                          color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text('Track',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ],
                    const Spacer(),
                    Text('Details →',
                        style: TextStyle(color: Colors.green.shade700,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Bottom Sheets ──────────────────────────────────────

  void _openNotifications() => showModalBottomSheet(
    context: context, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => StatefulBuilder(builder: (ctx, setBS) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(),
        _bsHeader(Icons.notifications_outlined, 'Notifications', Colors.orange),
        const SizedBox(height: 16),
        _switchRow(setBS, Icons.receipt_long, Colors.blue,
            'Order Updates', 'Place, confirm, delivered',
            _orderNotif, (v) { setBS(() => _orderNotif = v); setState(() => _orderNotif = v); _savePref('notif_order', v); }),
        _switchRow(setBS, Icons.local_offer, Colors.purple,
            'Offers & Deals', 'Discounts aur special offers',
            _promoNotif, (v) { setBS(() => _promoNotif = v); setState(() => _promoNotif = v); _savePref('notif_promo', v); }),
        _switchRow(setBS, Icons.delivery_dining, Colors.green,
            'Delivery Alerts', 'Agent pickup, on the way',
            _deliveryNotif, (v) { setBS(() => _deliveryNotif = v); setState(() => _deliveryNotif = v); _savePref('notif_delivery', v); }),
      ]),
    )),
  );

  void _openPrivacy() => showModalBottomSheet(
    context: context, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => StatefulBuilder(builder: (ctx, setBS) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(),
        _bsHeader(Icons.security, 'Privacy & Security', Colors.teal),
        const SizedBox(height: 16),
        _switchRow(setBS, Icons.location_on, Colors.blue,
            'Location Access', 'Delivery ke liye zaroori',
            _locationAccess, (v) { setBS(() => _locationAccess = v); setState(() => _locationAccess = v); _savePref('privacy_location', v); }),
        _switchRow(setBS, Icons.share, Colors.orange,
            'Data Sharing', 'Anonymous analytics',
            _dataSharing, (v) { setBS(() => _dataSharing = v); setState(() => _dataSharing = v); _savePref('privacy_data', v); }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade100)),
          child: Row(children: [
            Icon(Icons.lock, color: Colors.green.shade700, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Your data is encrypted and secure.',
                style: TextStyle(color: Colors.green.shade800, fontSize: 12))),
          ]),
        ),
      ]),
    )),
  );

  void _openChangePassword() {
    final oldC = TextEditingController(), newC = TextEditingController(),
        conC = TextEditingController();
    bool oV = false, nV = false, cV = false, loading = false;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bsCtx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          _bsHeader(Icons.lock_outline, 'Change Password', Colors.indigo),
          const SizedBox(height: 16),
          _pwField(oldC, 'Purana Password', oV, () => setBS(() => oV = !oV)),
          const SizedBox(height: 12),
          _pwField(newC, 'Naya Password', nV, () => setBS(() => nV = !nV)),
          const SizedBox(height: 12),
          _pwField(conC, 'Confirm Password', cV, () => setBS(() => cV = !cV)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : () async {
                if (oldC.text.isEmpty || newC.text.isEmpty || conC.text.isEmpty) {
                  _snack('Saare fields bharein!', Colors.orange); return;
                }
                if (newC.text != conC.text) {
                  _snack('Passwords do not match!', Colors.red); return;
                }
                if (newC.text.length < 6) {
                  _snack('Minimum 6 characters!', Colors.orange); return;
                }
                setBS(() => loading = true);
                final res = await ApiService.changePassword(oldC.text, newC.text);
                setBS(() => loading = false);
                if (mounted) Navigator.pop(bsCtx);
                _snack(res.containsKey('message') ? res['message'] : res['error'] ?? 'Error!',
                    res.containsKey('message') ? Colors.green.shade700 : Colors.red);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Change Password',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      )),
    );
  }

  void _openHelp() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.6,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _handle(),
          _bsHeader(Icons.help_outline, 'Help & Support', Colors.blue),
          const SizedBox(height: 16),
          GestureDetector(onTap: () => _launchUrl('tel:+919999999999'),
              child: _contactRow(Icons.phone, '+91 9999999999', 'Call Us', Colors.green)),
          GestureDetector(onTap: () => _launchUrl('mailto:support@prayagrajdelivery.com'),
              child: _contactRow(Icons.email_outlined, 'support@prayagrajdelivery.com',
                  'Email Us', Colors.blue)),
          GestureDetector(onTap: () => _launchUrl('https://wa.me/919999999999'),
              child: _contactRow(Icons.chat_outlined, 'WhatsApp',
                  'Instant reply', const Color(0xFF25D366))),
          const SizedBox(height: 16),
          const Text('FAQs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          _faq('Order cancel kaise kare?',
              'Go to Orders tab, tap on pending order and press Cancel.'),
          _faq('When will I get refund?',
              'Refund will be processed in 3-5 business days.'),
          _faq('Delivery charge?', 'Free delivery on all orders!'),
          _faq('Delivery time?', 'Delivered in 30-45 minutes.'),
        ]),
      ),
    ),
  );

  void _openRateApp() {
    int stars = 0;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const Text('Rate Our App', style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Aapka feedback bahut important hai!',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setBS(() => stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(i < stars ? Icons.star : Icons.star_border,
                      color: Colors.amber, size: 44),
                ),
              ))),
          if (stars > 0) ...[
            const SizedBox(height: 8),
            Text(['', '😞 Bahut bura', '😐 Thoda theek', '🙂 Accha',
                '😊 Bahut accha', '🎉 Ekdum best!'][stars],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: stars == 0 ? null : () {
                Navigator.pop(ctx);
                _snack('$stars ⭐ ke liye shukriya! 🎉', Colors.green.shade700);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 16)),
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
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bsCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Order #${order['id']}', style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
              Text('₹${order['total_price']}', style: TextStyle(
                  color: Colors.green.shade700, fontWeight: FontWeight.bold)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _sColor(order['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_sLabel(order['status']), style: TextStyle(
                  color: _sColor(order['status']), fontSize: 12,
                  fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              Icon(Icons.location_on, color: Colors.red.shade400, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(order['address'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _tStep(Icons.access_time,    'Pending',   step >= 0, Colors.amber),
            _tLine(step >= 1),
            _tStep(Icons.check_circle,   'Confirmed', step >= 1, Colors.blue),
            _tLine(step >= 2),
            _tStep(Icons.delivery_dining,'On Way',    step >= 2, Colors.orange),
            _tLine(step >= 3),
            _tStep(Icons.done_all,       'Delivered', step >= 3, Colors.green),
          ]),
          if (order['status'] == 'pending') ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(bsCtx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Cancel Order?'),
                      content: Text('Order #${order['id']} cancel karna chahte ho?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false),
                            child: const Text('No')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await ApiService.cancelOrder(order['id']);
                    if (mounted) {
                      _snack(ok ? '✅ Order cancelled!' : '❌ Could not cancel',
                          ok ? Colors.red.shade600 : Colors.orange);
                      if (ok) { setState(() => _isLoading = true); _loadOrders(); }
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Order Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Small helper widgets ───────────────────────────────

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _handle() => Center(child: Container(
    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2)),
  ));

  Widget _bsHeader(IconData icon, String title, Color color) => Row(children: [
    Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
    const SizedBox(width: 12),
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  ]);

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
    child: Column(children: children),
  );

  Widget _divider() => Divider(height: 1,
      color: Colors.grey.shade100, indent: 16, endIndent: 16);

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(
      fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _infoTile(IconData icon, String label, String val, Color color) =>
      ListTile(
        dense: true,
        leading: Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
        title: Text(label, style: TextStyle(
            color: Colors.grey.shade400, fontSize: 12)),
        subtitle: Text(val, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
      );

  Widget _settingTile(IconData icon, String title, String sub,
      Color color, VoidCallback onTap) =>
      ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
        title: Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: TextStyle(
            color: Colors.grey.shade400, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 12,
            color: Colors.grey.shade300),
      );

  Widget _switchTile({required IconData icon, required Color color,
    required String title, required String sub,
    required bool value, required ValueChanged<bool> onChanged}) =>
      ListTile(
        dense: true,
        leading: Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16)),
        title: Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(sub, style: TextStyle(
            color: Colors.grey.shade400, fontSize: 12)),
        trailing: Switch(value: value, activeColor: color, onChanged: onChanged),
      );

  Widget _switchRow(StateSetter setBS, IconData icon, Color color,
      String title, String sub, bool val, ValueChanged<bool> onChanged) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
            Text(sub, style: TextStyle(
                color: Colors.grey.shade400, fontSize: 11)),
          ])),
          Switch(value: val, activeColor: Colors.green, onChanged: onChanged),
        ]),
      );

  Widget _contactRow(IconData icon, String title, String sub, Color color) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
            Text(sub, style: TextStyle(
                color: Colors.grey.shade400, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade300),
        ]),
      );

  Widget _faq(String q, String a) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(q, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13)),
      children: [Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(a, style: TextStyle(
            color: Colors.grey.shade500, fontSize: 12)),
      )],
    ),
  );

  Widget _pwField(TextEditingController ctrl, String label,
      bool visible, VoidCallback onToggle) =>
      TextField(
        controller: ctrl,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: const Icon(Icons.lock_outline, size: 18),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade400, size: 18),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2)),
        ),
      );

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
        Text(label, style: TextStyle(
            color: active ? color : Colors.grey.shade400, fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ]);

  Widget _tLine(bool active) => Expanded(child: Container(
    height: 3, margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: active ? Colors.green : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(2),
    ),
  ));

  Widget _infoRow2(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text('$label: ', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );

  Color _sColor(String s) {
    switch (s) {
      case 'confirmed':        return Colors.blue;
      case 'delivered':        return Colors.green;
      case 'cancelled':        return Colors.red;
      case 'out_for_delivery': return Colors.orange;
      default:                 return Colors.amber;
    }
  }

  IconData _sIcon(String s) {
    switch (s) {
      case 'confirmed':        return Icons.check_circle;
      case 'delivered':        return Icons.done_all;
      case 'cancelled':        return Icons.cancel;
      case 'out_for_delivery': return Icons.delivery_dining;
      default:                 return Icons.access_time;
    }
  }

  String _sLabel(String s) {
    switch (s) {
      case 'confirmed':        return 'Confirmed';
      case 'delivered':        return 'Delivered';
      case 'cancelled':        return 'Cancelled';
      case 'out_for_delivery': return 'On the Way';
      default:                 return 'Pending';
    }
  }
}