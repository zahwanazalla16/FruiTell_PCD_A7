import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'dashboard_view.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (mounted && _authController.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardView()),
      );
    }
  }

  Future<void> _login() async {
    final success = await _authController.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.errorMessage ?? 'Login gagal')),
      );
    }
  }

  void _openRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterView()),
    );
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
      appBar: AppBar(title: const Text("Login FruiTell")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
              enabled: !_authController.isLoading,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              enabled: !_authController.isLoading,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _authController.isLoading ? null : _login,
                  child: _authController.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Login"),
                ),
                OutlinedButton(
                  onPressed: _authController.isLoading
                      ? null
                      : _openRegisterPage,
                  child: const Text("Daftar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
