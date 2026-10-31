import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;

  @override
  String toString() => code;
}

typedef AuthException = AuthFailure;

/// Firebase Auth controller with dual Username & Email login support,
/// password reset, account deletion, and offline guest mode.
class AuthController extends ChangeNotifier {
  AuthController(this._prefs, {required this.firebaseReady}) {
    _guest = _prefs.getBool(_guestKey) ?? false;
    _cachedUsername = _prefs.getString(_usernameKey);
    if (firebaseReady) {
      _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        _user = user;
        if (user != null) {
          await _loadUsername(user);
        } else {
          _cachedUsername = null;
        }
        _ready = true;
        notifyListeners();
      });
    } else {
      _ready = true;
    }
  }

  static const _guestKey = 'guest_mode';
  static const _usernameKey = 'cached_username';
  static final _usernameRe = RegExp(r'^[A-Za-z0-9_.]{3,20}$');
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final SharedPreferences _prefs;
  final bool firebaseReady;
  StreamSubscription<User?>? _sub;
  User? _user;
  String? _cachedUsername;
  bool _ready = false;
  late bool _guest;

  bool get ready => _ready;
  bool get signedIn => _user != null;
  bool get isGuest => _guest;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get username => _cachedUsername ?? _user?.displayName ?? _user?.email?.split('@').first;

  /// Show the login screen when Firebase is available, nobody is signed in,
  /// and the user has not chosen to continue in guest mode.
  bool get needsAuth => firebaseReady && !signedIn && !_guest;

  static bool isValidUsername(String raw) => _usernameRe.hasMatch(raw.trim());
  static bool isValidEmail(String raw) => _emailRe.hasMatch(raw.trim());

  DocumentReference<Map<String, dynamic>> _usernameDoc(String name) =>
      FirebaseFirestore.instance.collection('usernames').doc(name.trim().toLowerCase());

  Future<void> _loadUsername(User user) async {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      _cachedUsername = user.displayName;
      await _prefs.setString(_usernameKey, user.displayName!);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final uName = doc.data()?['username'] as String?;
      if (uName != null && uName.isNotEmpty) {
        _cachedUsername = uName;
        await _prefs.setString(_usernameKey, uName);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Resolve identifier (either email or username) to a valid email address.
  Future<String> _resolveEmail(String identifier) async {
    final id = identifier.trim();
    if (id.contains('@')) return id;

    // Lookup mapped email in Firestore 'usernames' collection
    try {
      final snap = await _usernameDoc(id).get().timeout(const Duration(seconds: 10));
      final resolved = snap.data()?['email'] as String?;
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    } catch (_) {}

    // Fallback: check legacy synthetic username domain for backwards compatibility
    return '$id@users.nesty.app';
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final name = username.trim();
    final mail = email.trim();

    if (!isValidUsername(name)) {
      throw const AuthFailure('invalid-username');
    }
    if (!isValidEmail(mail)) {
      throw const AuthFailure('invalid-email');
    }
    if (password.length < 6) {
      throw const AuthFailure('weak-password');
    }

    // Check if username is already taken
    final uDoc = _usernameDoc(name);
    try {
      final snap = await uDoc.get().timeout(const Duration(seconds: 10));
      if (snap.exists) {
        throw const AuthFailure('username-taken');
      }
    } on AuthFailure {
      rethrow;
    } catch (_) {}

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mail,
        password: password,
      );
      final user = cred.user!;
      final uid = user.uid;

      // Reserve username and save user profile
      try {
        await uDoc.set({
          'uid': uid,
          'email': mail,
          'username': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': name,
          'email': mail,
        }, SetOptions(merge: true));
        await user.updateDisplayName(name);
      } catch (e) {
        debugPrint('[AuthController] Firestore reservation note: $e');
      }

      _cachedUsername = name;
      await _prefs.setString(_usernameKey, name);
      await _setGuest(false);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code);
    }
  }

  Future<void> signIn(String identifier, String password) async {
    final id = identifier.trim();
    if (id.isEmpty) throw const AuthFailure('invalid-credential');

    try {
      final resolvedEmail = await _resolveEmail(id);
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );
      final user = cred.user!;
      await _loadUsername(user);
      await _setGuest(false);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code);
    }
  }

  Future<void> sendPasswordReset(String identifier) async {
    final id = identifier.trim();
    if (id.isEmpty) throw const AuthFailure('invalid-credential');
    try {
      final resolvedEmail = await _resolveEmail(id);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: resolvedEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code);
    }
  }

  Future<void> deleteAccount({String? password}) async {
    final user = _user;
    if (user == null) return;
    final uid = user.uid;
    final uName = username;

    // Re-authenticate if password provided
    if (password != null && password.isNotEmpty && user.email != null) {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
    }

    // Wipe username reservation
    if (uName != null && uName.isNotEmpty) {
      try {
        await _usernameDoc(uName).delete().timeout(const Duration(seconds: 10));
      } catch (_) {}
    }

    // Wipe user cloud document
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete().timeout(const Duration(seconds: 10));
    } catch (_) {}

    // Delete user from Firebase Auth
    await user.delete();
    _cachedUsername = null;
    await _prefs.remove(_usernameKey);
    await _setGuest(true);
    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _cachedUsername = null;
    await _prefs.remove(_usernameKey);
    await _setGuest(true);
    notifyListeners();
  }

  Future<void> continueAsGuest() => _setGuest(true);
  Future<void> exitGuest() => _setGuest(false);

  Future<void> _setGuest(bool value) async {
    _guest = value;
    await _prefs.setBool(_guestKey, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
