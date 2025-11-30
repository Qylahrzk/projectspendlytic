import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/db_service.dart';

class AuthService {
  // Access the Supabase Client
  final GoTrueClient _auth = Supabase.instance.client.auth;

  /// Get Current User
  User? get currentUser => _auth.currentUser;

  /// Auth State Stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// 🔐 Supabase Login
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Extract display name from metadata (Supabase stores extra info in metadata)
      final String? name = response.user?.userMetadata?['display_name'];

      // Save user session locally (Keep your existing SQLite logic)
      await DBService().saveUserData(
        email: email,
        name: name ?? 'Supabase User',
        provider: 'supabase',
      );

      dev.log("✅ Supabase login: ${response.user?.email}", name: 'AuthService');
      return response;
    } catch (e) {
      dev.log("❌ Login Error: $e", name: 'AuthService');
      rethrow;
    }
  }

  /// 🔐 Supabase Register
  Future<AuthResponse> createAccount({
    required String email,
    required String password,
    String? name, // Added name parameter to save it immediately
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        // Supabase stores name in 'data' (user_metadata)
        data: {'display_name': name ?? 'User'},
      );

      await DBService().saveUserData(
        email: email,
        name: name ?? 'Supabase User',
        provider: 'supabase',
      );

      dev.log("✅ Supabase sign up: ${response.user?.email}", name: 'AuthService');
      return response;
    } catch (e) {
      dev.log("❌ Sign Up Error: $e", name: 'AuthService');
      rethrow;
    }
  }

  /// 🔐 Supabase Sign Out + Clear SQLite
  Future<void> signOut() async {
    await _auth.signOut();
    await DBService().clearUserData();
    dev.log("✅ User signed out & SQLite cleared", name: 'AuthService');
  }

  /// 🔄 Update Display Name
  Future<void> updateUsername({required String username}) async {
    try {
      // In Supabase, we update the 'data' attribute
      await _auth.updateUser(
        UserAttributes(data: {'display_name': username}),
      );

      // Update name in SQLite too
      await DBService().updateUserName(username);

      dev.log("✅ Updated username: $username", name: 'AuthService');
    } catch (e) {
      dev.log("❌ Update Username Error: $e", name: 'AuthService');
      rethrow;
    }
  }

  /// ✉️ Forgot Password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email);
      dev.log("✅ Reset email sent to $email", name: 'AuthService');
    } catch (e) {
      dev.log("❌ Reset Password Error: $e", name: 'AuthService');
      rethrow;
    }
  }

  /// ❌ Delete account + SQLite
  /// Note: Supabase Client SDK does not allow deleting a user directly for security.
  /// Usually, you use an Edge Function.
  /// For this project, we will simulate it by clearing local data and signing out.
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    try {
      // 1. "Re-authenticate" by trying to sign in with the password provided
      await _auth.signInWithPassword(email: email, password: password);

      // 2. Since we can't delete from client, we just clear local data
      // If you really need to delete the user from the cloud, you need an Edge Function.
      // For now, we will just sign them out and wipe the DB.
      
      await DBService().clearUserData();
      await _auth.signOut();
      
      dev.log("✅ User data cleared (Soft Delete)", name: 'AuthService');
    } catch (e) {
      dev.log("❌ Delete Account Error (Wrong Password?): $e", name: 'AuthService');
      rethrow;
    }
  }

  /// 🔑 Change password
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      // 1. "Re-authenticate" first to ensure the current password is correct
      await _auth.signInWithPassword(email: email, password: currentPassword);

      // 2. Update to new password
      await _auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      dev.log("✅ Password updated for $email", name: 'AuthService');
    } catch (e) {
      dev.log("❌ Change Password Error: $e", name: 'AuthService');
      rethrow;
    }
  }
}