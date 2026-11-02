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
/// password reset, account deletion, username customization, and offline guest mode.
class AuthController extends ChangeNotifier {
  AuthController(this._prefs, {required this.firebaseReady}) {
    _guest = _prefs.getBool(_guestKey) ?? false;
    _cachedUsername = _prefs.getString(_usernameKey);
    if (firebaseReady) {
      // userChanges() emits events when displayName and user profile change
      _sub = FirebaseAuth.instance.userChanges().listen((user) async {
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
  String? get username =>
      _cachedUsername ??
      _user?.displayName ??
      _user?.email?.split('@').first;

  /// Show the login screen when Firebase is available, nobody is signed in,
  /// and the user has not chosen to continue in guest mode.
  bool get needsAuth => firebaseReady && !signedIn && !_guest;

  static bool isValidUsername(String raw) => _usernameRe.hasMatch(raw.trim());
  static bool isValidEmail(String raw) => _emailRe.hasMatch(raw.trim());

  DocumentReference<Map<String, dynamic>> _usernameDoc(String name) =>
      FirebaseFirestore.instance.collection('usernames').doc(name.trim().toLowerCase());

  Future<void> setCachedUsername(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _cachedUsername = clean;
    await _prefs.setString(_usernameKey, clean);
    final user = _user;
    if (user != null && (user.displayName == null || user.displayName != clean)) {
      try {
        await user.updateDisplayName(clean);
      } catch (e) {
        debugPrint('[AuthController] updateDisplayName note: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _loadUsername(User user) async {
    // 1. Check user.displayName
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      _cachedUsername = user.displayName!.trim();
      await _prefs.setString(_usernameKey, _cachedUsername!);
      notifyListeners();
      return;
    }

    // 2. Check users/{uid} document
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final uName = doc.data()?['username'] as String?;
      if (uName != null && uName.trim().isNotEmpty) {
        _cachedUsername = uName.trim();
        await _prefs.setString(_usernameKey, _cachedUsername!);
        try {
          await user.updateDisplayName(_cachedUsername!);
        } catch (e) {
          debugPrint('[AuthController] updateDisplayName note: $e');
        }
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('[AuthController] Load username from users doc: $e');
    }

    // 3. Fallback: Search usernames collection for matching uid
    try {
      final snap = await FirebaseFirestore.instance
          .collection('usernames')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      if (snap.docs.isNotEmpty) {
        final uName = snap.docs.first.data()['username'] as String?;
        if (uName != null && uName.trim().isNotEmpty) {
          _cachedUsername = uName.trim();
          await _prefs.setString(_usernameKey, _cachedUsername!);
          try {
            await user.updateDisplayName(_cachedUsername!);
          } catch (e) {
            debugPrint('[AuthController] updateDisplayName note: $e');
          }
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('[AuthController] Load username from usernames collection: $e');
    }
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
    } catch (e) {
      debugPrint('[AuthController] Username email lookup: $e');
    }
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

    // Create Firebase Auth account first
    final UserCredential cred;
    try {
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code);
    }
    final user = cred.user!;
    final uid = user.uid;

    // Atomically reserve username via transaction to prevent race conditions
    final uDoc = _usernameDoc(name);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(uDoc);
        if (snap.exists) {
          throw const AuthFailure('username-taken');
        }
        tx.set(uDoc, {
          'uid': uid,
          'email': mail,
          'username': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(
          FirebaseFirestore.instance.collection('users').doc(uid),
          {'username': name, 'email': mail},
          SetOptions(merge: true),
        );
      }).timeout(const Duration(seconds: 10));
      await user.updateDisplayName(name);
    } on AuthFailure {
      // Username taken — delete the just-created auth account
      try { await user.delete(); } catch (_) {}
      rethrow;
    } catch (e) {
      debugPrint('[AuthController] Firestore reservation note: $e');
    }

    _cachedUsername = name;
    await _prefs.setString(_usernameKey, name);
    await _setGuest(false);
    notifyListeners();
  }

  Future<void> signIn(String identifier, String password) async {
    final id = identifier.trim();
    if (id.isEmpty) throw const AuthFailure('invalid-credential');

    final isUsernameLogin = !id.contains('@');

    try {
      final resolvedEmail = await _resolveEmail(id);
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );
      final user = cred.user!;

      if (isUsernameLogin) {
        _cachedUsername = id;
        await _prefs.setString(_usernameKey, id);
        try {
          await user.updateDisplayName(id);
        } catch (e) {
          debugPrint('[AuthController] updateDisplayName note: $e');
        }
      } else {
        await _loadUsername(user);
      }

      await _setGuest(false);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code);
    }
  }

  /// Update or customize username for the current signed-in account.
  Future<void> updateUsername(String newUsername) async {
    final user = _user;
    if (user == null) return;
    final cleanNew = newUsername.trim();
    if (!isValidUsername(cleanNew)) {
      throw const AuthFailure('invalid-username');
    }

    final oldUsername = username;
    if (oldUsername != null && oldUsername.toLowerCase() == cleanNew.toLowerCase()) {
      return; // No change
    }

    final newDoc = _usernameDoc(cleanNew);

    // Atomically check-and-set via transaction to prevent race conditions
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(newDoc);
      if (snap.exists) {
        final existingUid = snap.data()?['uid'];
        if (existingUid != user.uid) {
          throw const AuthFailure('username-taken');
        }
      }
      tx.set(newDoc, {
        'uid': user.uid,
        'email': user.email ?? '',
        'username': cleanNew,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        FirebaseFirestore.instance.collection('users').doc(user.uid),
        {'username': cleanNew},
        SetOptions(merge: true),
      );
    }).timeout(const Duration(seconds: 10));

    // Delete old mapping if different
    if (oldUsername != null &&
        oldUsername.isNotEmpty &&
        oldUsername.toLowerCase() != cleanNew.toLowerCase()) {
      try {
        await _usernameDoc(oldUsername).delete();
      } catch (e) {
        debugPrint('[AuthController] Old username cleanup note: $e');
      }
    }

    try {
      await user.updateDisplayName(cleanNew);
    } catch (e) {
      debugPrint('[AuthController] DisplayName update note: $e');
    }

    _cachedUsername = cleanNew;
    await _prefs.setString(_usernameKey, cleanNew);
    notifyListeners();
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
      } catch (e) {
        debugPrint('[AuthController] Username cleanup on delete: $e');
      }
    }

    // Wipe user cloud document
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[AuthController] User doc cleanup on delete: $e');
    }

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
