import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 🔐 Firebase Login
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save user session locally
    await DBService().saveUserData(
      email: email,
      name: cred.user?.displayName ?? 'Firebase User',
      provider: 'firebase',
    );

    dev.log("✅ Firebase login: ${cred.user?.email}", name: 'AuthService');
    return cred;
  }

  /// 🔐 Firebase Register
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await DBService().saveUserData(
      email: email,
      name: cred.user?.displayName ?? 'Firebase User',
      provider: 'firebase',
    );

    dev.log("✅ Firebase sign up: ${cred.user?.email}", name: 'AuthService');
    return cred;
  }

  /// 🔐 Firebase Sign Out + Clear SQLite
  Future<void> signOut() async {
    await _auth.signOut();
    await DBService().clearUserData();
    dev.log("✅ User signed out & SQLite cleared", name: 'AuthService');
  }

  /// 🔄 Firebase Display Name
  Future<void> updateUsername({required String username}) async {
    await currentUser?.updateDisplayName(username);
    await currentUser?.reload();

    // Update name in SQLite too
    await DBService().updateUserName(username);

    dev.log("✅ Updated username: $username", name: 'AuthService');
  }

  /// ✉️ Forgot Password
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
    dev.log("✅ Reset email sent to $email", name: 'AuthService');
  }

  /// ❌ Delete account + SQLite
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser?.reauthenticateWithCredential(credential);
    await currentUser?.delete();
    await DBService().clearUserData();
    dev.log("✅ Firebase account deleted", name: 'AuthService');
  }

  /// 🔑 Change password
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser?.reauthenticateWithCredential(credential);
    await currentUser?.updatePassword(newPassword);
    dev.log("✅ Password updated for $email", name: 'AuthService');
  }
}
