import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. DAFTAR (Sign Up)
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  // 2. MASUK (Sign In)
  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  // 3. KELUAR (Sign Out)
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // 4. CEK USER AKTIF
  User? get currentUser => _client.auth.currentUser;
}
