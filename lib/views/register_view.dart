import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _authController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong'),
          backgroundColor: Color(0xFF7D2F54),
        ),
      );
      return;
    }

    final success = await _authController.signUp(email, password);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daftar berhasil. Silakan login.'),
            backgroundColor: Color(0xFFE93E9D),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authController.errorMessage ?? 'Daftar gagal'),
            backgroundColor: const Color(0xFF7D2F54),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _authController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFFFD1E6), // Stronger Rose Pink
              Color(0xFFFFF9E6), // Cream Middle
              Color(0xFFFFF6B8), // Stronger Warm Yellow
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7D2F54)),
                ),
                const SizedBox(height: 10),

                // Logo & Header
                Center(
                  child: Column(
                    children: [
                      // Brand Logo Icon
                      Image.asset(
                        'assets/images/LogoFruiTell.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Buat Akun Baru',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7D2F54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mulailah perjalanan Anda hidup lebih sehat dengan buah segar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6A5A62),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Email Form Field
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7D2F54),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_authController.isLoading,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Masukkan email Anda',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFE93E9D)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE93E9D), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Form Field
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7D2F54),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_authController.isLoading,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Masukkan password Anda',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFFE93E9D)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE93E9D), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _authController.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE93E9D),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFFE93E9D).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _authController.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Redirect Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          color: Color(0xFF6A5A62),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: _authController.isLoading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Masuk Sekarang',
                          style: TextStyle(
                            color: Color(0xFFE93E9D),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
