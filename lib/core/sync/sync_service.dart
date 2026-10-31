import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/bills/data/bills_controller.dart';
import '../../features/gallon/data/gallon_controller.dart';
import '../../features/laundry/data/laundry_controller.dart';
import '../../features/profile/profile_controller.dart';
import '../../features/routine/data/routines_controller.dart';
import '../../features/supplies/data/supplies_controller.dart';
import '../../features/token/data/token_controller.dart';

enum SyncState { idle, syncing, synced, offline, error }

/// Local-first sync.
///
/// The phone is always the working copy (SharedPreferences), so the app works
/// offline. When signed in, one Firestore document `users/{uid}` mirrors it:
///   `{ updatedAt: <ms>, payload: <JSON string>, ...profile fields }`
/// Conflict rule: newest `updatedAt` wins. The same JSON is used for the
/// offline import/export file.
class SyncService extends ChangeNotifier {
  SyncService(
    this._prefs, {
    required SuppliesController supplies,
    required RoutinesController routines,
    required TokenController token,
    required GallonController gallon,
    required LaundryController laundry,
    required BillsController bills,
    required ProfileController profile,
    required AuthController auth,
  })  : _supplies = supplies,
        _routines = routines,
        _token = token,
        _gallon = gallon,
        _laundry = laundry,
        _bills = bills,
        _profile = profile,
        _auth = auth {
    _localUpdatedAt = _prefs.getInt(_tsKey) ?? 0;
    final lastMs = _prefs.getInt(_lastSyncKey);
    if (lastMs != null && lastMs > 0) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
    _supplies.addListener(_onLocalChange);
    _routines.addListener(_onLocalChange);
    _token.addListener(_onLocalChange);
    _gallon.addListener(_onLocalChange);
    _laundry.addListener(_onLocalChange);
    _bills.addListener(_onLocalChange);
    _profile.addListener(_onLocalChange);
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  static const _tsKey = 'local_updated_at';
  static const _lastSyncKey = 'last_cloud_sync_time';
  final SharedPreferences _prefs;
  final SuppliesController _supplies;
  final RoutinesController _routines;
  final TokenController _token;
  final GallonController _gallon;
  final LaundryController _laundry;
  final BillsController _bills;
  final ProfileController _profile;
  final AuthController _auth;

  SyncState _state = SyncState.idle;
  SyncState get state => _state;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  int _localUpdatedAt = 0;
  bool _applying = false; // true while we write remote/imported data locally
  String? _lastUid;
  Timer? _debounce;

  void _setState(SyncState s) {
    _state = s;
    notifyListeners();
  }

  void _recordSyncSuccess() {
    _lastSyncTime = DateTime.now();
    _prefs.setInt(_lastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);
    notifyListeners();
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  // ------------------------------------------------------------ snapshot

  Map<String, dynamic> snapshot() => {
        'app': 'nesty',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'supplies': _supplies.toJson(),
        'routines': _routines.toJson(),
        'token': _token.toJson(),
        'gallon': _gallon.toJson(),
        'laundry': _laundry.toJson(),
        'bills': _bills.toJson(),
        'profile': _profile.toJson(),
      };

  void _applyMap(Map<String, dynamic> map) {
    // Parse everything first so a bad file cannot leave half-applied data.
    SuppliesController.parse(map['supplies'] as List<dynamic>);
    RoutinesController.parse(map['routines'] as List<dynamic>);
    final tokenMap = map['token'] as Map<String, dynamic>?;
    final gallonMap = map['gallon'] as Map<String, dynamic>?;
    if (tokenMap != null) TokenController.parse(tokenMap);
    if (gallonMap != null) GallonController.parse(gallonMap);
    final laundryList = map['laundry'] as List<dynamic>?;
    if (laundryList != null) LaundryController.parse(laundryList);
    final billsList = map['bills'] as List<dynamic>?;
    if (billsList != null) BillsController.parse(billsList);
    final profileMap = map['profile'] as Map<String, dynamic>?;

    _applying = true;
    try {
      _supplies.loadJson(map['supplies'] as List<dynamic>);
      _routines.loadJson(map['routines'] as List<dynamic>);
      tokenMap != null ? _token.loadJson(tokenMap) : _token.resetToDefaults();
      gallonMap != null ? _gallon.loadJson(gallonMap) : _gallon.resetToDefaults();
      laundryList != null ? _laundry.loadJson(laundryList) : _laundry.resetToDefaults();
      billsList != null ? _bills.loadJson(billsList) : _bills.resetToDefaults();
      if (profileMap != null) {
        _profile.loadJson(profileMap);
      }
    } finally {
      _applying = false;
    }
  }

  void _setLocalTs(int ts) {
    _localUpdatedAt = ts;
    _prefs.setInt(_tsKey, ts);
  }

  /// Used by the offline import. Throws [FormatException] for a bad file.
  void importJson(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const FormatException('Invalid JSON');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != 'nesty' ||
        decoded['supplies'] is! List ||
        decoded['routines'] is! List) {
      throw const FormatException('Not a Nesty backup');
    }
    try {
      _applyMap(decoded);
    } catch (_) {
      throw const FormatException('Corrupt backup');
    }
    _setLocalTs(DateTime.now().millisecondsSinceEpoch); // import wins over cloud
    _schedulePush();
    notifyListeners();
  }

  // --------------------------------------------------------------- events

  void _onLocalChange() {
    if (_applying) return;
    _setLocalTs(DateTime.now().millisecondsSinceEpoch);
    _schedulePush();
  }

  void _onAuthChanged() {
    final uid = _auth.uid;
    if (uid == _lastUid) return;
    final wasSignedIn = _lastUid != null;
    _lastUid = uid;
    if (uid != null) {
      _pullAndMerge();
    } else {
      _debounce?.cancel();
      if (wasSignedIn) _resetLocal(); // never leak one account into another
      _setState(SyncState.idle);
    }
  }

  void _resetLocal() {
    _applying = true;
    try {
      _supplies.resetToDefaults();
      _routines.resetToDefaults();
      _token.resetToDefaults();
      _gallon.resetToDefaults();
      _laundry.resetToDefaults();
      _bills.resetToDefaults();
      _profile.resetToDefaults();
    } finally {
      _applying = false;
    }
    _setLocalTs(0);
  }

  // ------------------------------------------------------------ cloud I/O

  void _schedulePush() {
    if (_auth.uid == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _push);
  }

  Future<void> syncNow() => _auth.uid == null ? Future.value() : _pullAndMerge();

  /// Force push local data to Firestore
  Future<void> sendToCloud() async {
    final uid = _auth.uid;
    if (uid == null) return;
    _setLocalTs(DateTime.now().millisecondsSinceEpoch);
    await _push();
  }

  /// Force download remote data from Firestore and apply locally
  Future<void> fetchFromCloud() async {
    final uid = _auth.uid;
    if (uid == null) return;
    _setState(SyncState.syncing);
    try {
      final snap = await _doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      final data = snap.data();
      if (data != null) {
        // Restore username if available in document
        final rUsername = data['username'] as String?;
        if (rUsername != null && rUsername.trim().isNotEmpty) {
          _auth.setCachedUsername(rUsername.trim());
        }

        // Restore profile fields directly from doc if available
        if (data['nickname'] != null || data['photo'] != null) {
          _profile.loadJson({
            'nickname': data['nickname'],
            'photo': data['photo'],
            'updatedAt': data['profileUpdatedAt'] ?? data['updatedAt'] ?? 0,
          });
        }

        final rawPayload = data['payload'] as String?;
        if (rawPayload != null && rawPayload.isNotEmpty) {
          final payload = jsonDecode(rawPayload) as Map<String, dynamic>;
          _applyMap(payload);
        }

        final remoteTs = (data['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
        _setLocalTs(remoteTs);
        _setState(SyncState.synced);
        _recordSyncSuccess();
      }
    } catch (_) {
      _setState(SyncState.error);
      rethrow;
    }
  }

  Future<void> _push() async {
    final uid = _auth.uid;
    if (uid == null) return;
    _setState(SyncState.syncing);
    try {
      final photoB64 = _profile.photo != null ? base64Encode(_profile.photo!) : null;
      final profileTs = _profile.toJson()['updatedAt'] ?? _localUpdatedAt;

      await _doc(uid)
          .set({
            'updatedAt': _localUpdatedAt,
            'username': _auth.username,
            'email': _auth.email,
            'nickname': _profile.nickname,
            'photo': photoB64,
            'profileUpdatedAt': profileTs,
            'payload': jsonEncode(snapshot()),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
      _setState(SyncState.synced);
      _recordSyncSuccess();
    } on TimeoutException {
      // Firestore keeps the write queued on the device and sends it when online.
      _setState(SyncState.offline);
    } catch (_) {
      _setState(SyncState.error);
    }
  }

  Future<void> _pullAndMerge() async {
    final uid = _auth.uid;
    if (uid == null) return;
    _setState(SyncState.syncing);
    try {
      final snap = await _doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      if (_auth.uid != uid) return; // account changed in the meantime

      final data = snap.data();
      if (data == null) {
        await _push(); // brand new account: upload what is on this phone
        return;
      }

      // Restore username if present
      final rUsername = data['username'] as String?;
      if (rUsername != null && rUsername.trim().isNotEmpty) {
        _auth.setCachedUsername(rUsername.trim());
      }

      // Restore profile fields directly if present
      if (data['nickname'] != null || data['photo'] != null) {
        _profile.loadJson({
          'nickname': data['nickname'],
          'photo': data['photo'],
          'updatedAt': data['profileUpdatedAt'] ?? data['updatedAt'] ?? 0,
        });
      }

      final remoteTs = (data['updatedAt'] as num?)?.toInt() ?? 0;
      if (remoteTs > _localUpdatedAt) {
        final rawPayload = data['payload'] as String?;
        if (rawPayload != null && rawPayload.isNotEmpty) {
          _applyMap(jsonDecode(rawPayload) as Map<String, dynamic>);
        }
        _setLocalTs(remoteTs);
        _setState(SyncState.synced);
        _recordSyncSuccess();
      } else if (_localUpdatedAt > remoteTs) {
        await _push();
      } else {
        _setState(SyncState.synced);
        _recordSyncSuccess();
      }
    } on TimeoutException {
      _setState(SyncState.offline);
    } on FirebaseException catch (e) {
      _setState(e.code == 'unavailable' ? SyncState.offline : SyncState.error);
    } catch (_) {
      _setState(SyncState.error);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _supplies.removeListener(_onLocalChange);
    _routines.removeListener(_onLocalChange);
    _token.removeListener(_onLocalChange);
    _gallon.removeListener(_onLocalChange);
    _laundry.removeListener(_onLocalChange);
    _bills.removeListener(_onLocalChange);
    _profile.removeListener(_onLocalChange);
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
