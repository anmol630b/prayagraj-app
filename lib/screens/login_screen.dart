import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading       = false;
  bool _obscurePassword = true;
  String _errorMessage  = '';

  void _login() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Username aur password dono bharein!');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final result = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      setState(() => _isLoading = false);
      if (result.containsKey('access')) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        setState(() => _errorMessage = 'Username ya password galat hai!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Server se connect nahi ho pa raha!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(children: [

          // ── Green top section ───────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(40)),
            ),
            padding: EdgeInsets.fromLTRB(
                28, MediaQuery.of(context).padding.top + 40, 28, 40),
            child: Column(children: [
              // Logo circle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Prayagraj Delivery',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text('Ghar baithe fresh saman mangao!',
                  style: TextStyle(color: Colors.white.withOpacity(0.8),
                      fontSize: 14)),
            ]),
          ),

          // ── Form section ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              const Text('Welcome Back! 👋',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Text('Login karke order karo',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),

              const SizedBox(height: 28),

              // Username field
              _inputField(
                controller: _usernameController,
                label: 'Username',
                hint: 'Apna username likho',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              // Password field
              _inputField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Apna password likho',
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              // Error message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Login',
                          style: TextStyle(fontSize: 17, color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ya', style: TextStyle(color: Colors.grey.shade400)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ]),

              const SizedBox(height: 20),

              // Sign up button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SignupScreen())),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade700, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Naya Account Banao',
                      style: TextStyle(fontSize: 16,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),

              // Terms
              Center(
                child: Text('Login karke aap hamare terms accept karte ho',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    textAlign: TextAlign.center),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Colors.black87)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade400, size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ]);
  }
}