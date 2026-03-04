import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading       = false;
  bool _obscurePassword = true;
  String _errorMessage  = '';

  void _signup() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Saare fields bharein!');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final result = await ApiService.register(
        _usernameController.text.trim(),
        _passwordController.text,
        _emailController.text.trim(),
      );
      setState(() => _isLoading = false);
      if (result.containsKey('message')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Account ban gaya! Login karo 🎉'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        setState(() => _errorMessage = result['error'] ?? 'Error! Dobara try karo');
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
                28, MediaQuery.of(context).padding.top + 36, 28, 36),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_outlined,
                    size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Account Banao',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text('Free mein register karo!',
                  style: TextStyle(color: Colors.white.withOpacity(0.8),
                      fontSize: 14)),
            ]),
          ),

          // ── Form section ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              const Text('Naya Account 🚀',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Text('Apni details bharke register karo',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),

              const SizedBox(height: 28),

              // Username
              _inputField(
                controller: _usernameController,
                label: 'Username',
                hint: 'Unique username likho',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              // Email
              _inputField(
                controller: _emailController,
                label: 'Email',
                hint: 'Apni email likho',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Password
              _inputField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Strong password likho (min 6 chars)',
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

              // Signup button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
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
                      : const Text('Account Banao',
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

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade700, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Pehle se Account Hai? Login Karo',
                      style: TextStyle(fontSize: 15,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text('Register karke aap hamare terms accept karte ho',
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 13, color: Colors.black87)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
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