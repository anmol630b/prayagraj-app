import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'order_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isNavVisible = true;
  final GlobalKey<CartScreenState> _cartKey = GlobalKey<CartScreenState>();
  final GlobalKey<OrderScreenState> _orderKey = GlobalKey<OrderScreenState>();

  void onScroll(bool isScrollingDown) {
    if (isScrollingDown && _isNavVisible) {
      setState(() => _isNavVisible = false);
    } else if (!isScrollingDown && !_isNavVisible) {
      setState(() => _isNavVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onScroll: onScroll),
          CartScreen(key: _cartKey),
          OrderScreen(key: _orderKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isNavVisible ? Offset.zero : const Offset(0, 1),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isNavVisible ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    _isNavVisible = true;
                  });
                  if (index == 1) _cartKey.currentState?.loadCart();
                  if (index == 2) _orderKey.currentState?.loadOrders();
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: Colors.green.shade700,
                unselectedItemColor: Colors.grey.shade400,
                selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart_outlined),
                    activeIcon: Icon(Icons.shopping_cart),
                    label: 'Cart',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_outlined),
                    activeIcon: Icon(Icons.receipt_long),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
