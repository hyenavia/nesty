import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_controller.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._prefs, {required AuthController auth}) : _auth = auth {
    _auth.addListener(_onAuthChanged);
    _loadProfile();
  }

  static const _timeout = Duration(seconds: 15);
  final SharedPreferences _prefs;
  final AuthController _auth;

  String? _nickname;
  Uint8List? _photo;

  String? get nickname => _nickname;
  Uint8List? get photo => _photo;

  String _nickKey(String uid) => 'nickname_$uid';
  String _photoKey(String uid) => 'photo_$uid';
  String _updatedKey(String uid) => 'profile_updated_$uid';

  String? get _uid => _auth.uid;

  void _onAuthChanged() {
    _loadProfile();
  }

  void _loadProfile() {
    final uid = _uid;
    if (uid == null) {
      _nickname = _prefs.getString('guest_nickname');
      final b64 = _prefs.getString('guest_photo');
      _photo = b64 != null ? base64Decode(b64) : null;
      notifyListeners();
      return;
    }

    _nickname = _prefs.getString(_nickKey(uid));
    final b64 = _prefs.getString(_photoKey(uid));
    _photo = b64 != null ? base64Decode(b64) : null;
    notifyListeners();

    // Check remote cloud profile in background
    restoreFromCloud();
  }

  Map<String, dynamic> toJson() => {
        'nickname': _nickname,
        'photo': _photo != null ? base64Encode(_photo!) : null,
        'updatedAt': _uid == null ? 0 : (_prefs.getInt(_updatedKey(_uid!)) ?? 0),
      };

  void loadJson(Map<String, dynamic> json) {
    final nick = json['nickname'] as String?;
    final photoB64 = json['photo'] as String?;
    final updatedAt = (json['updatedAt'] as num?)?.toInt() ?? 0;

    final uid = _uid;
    final localAt = uid == null ? 0 : (_prefs.getInt(_updatedKey(uid)) ?? 0);

    // Update if remote is newer or local is uninitialized
    if (updatedAt >= localAt || _nickname == null) {
      _nickname = nick;
      _photo = photoB64 != null ? base64Decode(photoB64) : null;
      if (uid != null) {
        if (nick != null && nick.isNotEmpty) {
          _prefs.setString(_nickKey(uid), nick);
        } else {
          _prefs.remove(_nickKey(uid));
        }
        if (photoB64 != null && photoB64.isNotEmpty) {
          _prefs.setString(_photoKey(uid), photoB64);
        } else {
          _prefs.remove(_photoKey(uid));
        }
        _prefs.setInt(_updatedKey(uid), updatedAt);
      }
      notifyListeners();
    }
  }

  void resetToDefaults() {
    _nickname = null;
    _photo = null;
    notifyListeners();
  }

  Future<void> setNickname(String value) async {
    final nick = value.trim();
    _nickname = nick.isEmpty ? null : nick;
    final uid = _uid;

    if (uid == null) {
      if (nick.isEmpty) {
        await _prefs.remove('guest_nickname');
      } else {
        await _prefs.setString('guest_nickname', nick);
      }
    } else {
      if (nick.isEmpty) {
        await _prefs.remove(_nickKey(uid));
      } else {
        await _prefs.setString(_nickKey(uid), nick);
      }
      await _prefs.setInt(_updatedKey(uid), DateTime.now().millisecondsSinceEpoch);
      uploadToCloud();
    }
    notifyListeners();
  }

  Future<void> setPhoto(Uint8List? bytes) async {
    _photo = bytes;
    final uid = _uid;

    if (uid == null) {
      if (bytes == null) {
        await _prefs.remove('guest_photo');
      } else {
        await _prefs.setString('guest_photo', base64Encode(bytes));
      }
    } else {
      if (bytes == null) {
        await _prefs.remove(_photoKey(uid));
      } else {
        await _prefs.setString(_photoKey(uid), base64Encode(bytes));
      }
      await _prefs.setInt(_updatedKey(uid), DateTime.now().millisecondsSinceEpoch);
      uploadToCloud();
    }
    notifyListeners();
  }

  DocumentReference<Map<String, dynamic>>? _metaDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('meta').doc('profile');

  DocumentReference<Map<String, dynamic>>? _userDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> uploadToCloud() async {
    final uid = _uid;
    if (uid == null) return;
    final photoB64 = _photo != null ? base64Encode(_photo!) : null;
    final ts = _prefs.getInt(_updatedKey(uid)) ?? DateTime.now().millisecondsSinceEpoch;

    // 1. Mirror directly to root users/{uid} document with merge: true
    try {
      await _userDoc(uid)?.set({
        'nickname': _nickname,
        'photo': photoB64,
        'profileUpdatedAt': ts,
      }, SetOptions(merge: true)).timeout(_timeout);
    } catch (e) {
      debugPrint('[ProfileController] Root doc profile update note: $e');
    }

    // 2. Also save to meta/profile subcollection
    try {
      await _metaDoc(uid)?.set({
        'nickname': _nickname,
        'photo': photoB64,
        'updatedAt': ts,
      }, SetOptions(merge: true)).timeout(_timeout);
    } catch (e) {
      debugPrint('[ProfileController] Meta doc upload note: $e');
    }
  }

  Future<void> restoreFromCloud() async {
    final uid = _uid;
    if (uid == null) return;

    // 1. Try reading from root users/{uid} document first
    try {
      final snap = await _userDoc(uid)?.get().timeout(_timeout);
      final data = snap?.data();
      if (data != null && (data.containsKey('nickname') || data.containsKey('photo'))) {
        final remoteAt = (data['profileUpdatedAt'] as num?)?.toInt() ?? (data['updatedAt'] as num?)?.toInt() ?? 0;
        final localAt = _prefs.getInt(_updatedKey(uid)) ?? 0;
        if (remoteAt > localAt || _nickname == null) {
          final rNick = data['nickname'] as String?;
          final rPhotoB64 = data['photo'] as String?;
          _nickname = rNick;
          _photo = rPhotoB64 != null ? base64Decode(rPhotoB64) : null;
          if (rNick != null) {
            await _prefs.setString(_nickKey(uid), rNick);
          }
          if (rPhotoB64 != null) {
            await _prefs.setString(_photoKey(uid), rPhotoB64);
          }
          await _prefs.setInt(_updatedKey(uid), remoteAt);
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('[ProfileController] Root doc restore note: $e');
    }

    // 2. Fallback to meta/profile subcollection
    try {
      final doc = _metaDoc(uid);
      if (doc == null) return;
      final snap = await doc.get().timeout(_timeout);
      final data = snap.data();
      if (data == null) return;

      final remoteAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
      final localAt = _prefs.getInt(_updatedKey(uid)) ?? 0;
      if (remoteAt <= localAt && _nickname != null) return;

      final rNick = data['nickname'] as String?;
      final rPhotoB64 = data['photo'] as String?;

      _nickname = rNick;
      _photo = rPhotoB64 != null ? base64Decode(rPhotoB64) : null;

      if (rNick != null) {
        await _prefs.setString(_nickKey(uid), rNick);
      } else {
        await _prefs.remove(_nickKey(uid));
      }

      if (rPhotoB64 != null) {
        await _prefs.setString(_photoKey(uid), rPhotoB64);
      } else {
        await _prefs.remove(_photoKey(uid));
      }

      await _prefs.setInt(_updatedKey(uid), remoteAt);
      notifyListeners();
    } catch (e) {
      debugPrint('[ProfileController] Cloud restore error: $e');
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
