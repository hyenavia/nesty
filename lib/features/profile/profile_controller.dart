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

  Future<void> uploadToCloud() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = _metaDoc(uid);
      if (doc == null) return;
      await doc.set({
        'nickname': _nickname,
        'photo': _photo != null ? base64Encode(_photo!) : null,
        'updatedAt': _prefs.getInt(_updatedKey(uid)) ?? DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true)).timeout(_timeout);
    } catch (e) {
      debugPrint('[ProfileController] Cloud upload error: $e');
    }
  }

  Future<void> restoreFromCloud() async {
    final uid = _uid;
    if (uid == null) return;
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
