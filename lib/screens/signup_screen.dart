import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _signup() async {
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill all fields');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.register(username, password, email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      print('Signup response: $response');

      if (response.containsKey('error')) {
        _showError(response['error'].toString());
      } else {
        // Success — login kar do automatically
        final loginResult = await ApiService.login(username, password);
        if (!mounted) return;
        if (loginResult.containsKey('access')) {
          Navigator.pushReplacement(context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const LoginScreen(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ));
          _showSuccess('Account created! Please login');
        } else {
          _showSuccess('Account created! Please login');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Connection error: $e');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Create Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Sign up for free',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              const SizedBox(height: 32),

              // Username
              _field(_usernameCtrl, 'Username', Icons.person_outline),
              const SizedBox(height: 16),

              // Email
              _field(_emailCtrl, 'Email', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Password
              _passwordField(_passwordCtrl, 'Password', _obscure1, () {
                setState(() => _obscure1 = !_obscure1);
              }),
              const SizedBox(height: 16),

              // Confirm Password
              _passwordField(_confirmCtrl, 'Confirm Password', _obscure2, () {
                setState(() => _obscure2 = !_obscure2);
              }),

              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Sign Up',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                    style: TextStyle(color: Colors.grey.shade500)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Login',
                      style: TextStyle(color: Colors.green.shade700,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
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
            borderSide: BorderSide(color: Colors.green.shade600, width: 1.5)),
        labelStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined
              : Icons.visibility_outlined, color: Colors.grey.shade400),
          onPressed: toggle,
        ),
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
            borderSide: BorderSide(color: Colors.green.shade600, width: 1.5)),
        labelStyle: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }
}
