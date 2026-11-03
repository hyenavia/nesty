import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/bills/data/bills_controller.dart';
import '../../features/gallon/data/gallon_controller.dart';
import '../../features/laundry/data/laundry_controller.dart';
import '../../features/laundry/data/laundry_order.dart';
import '../../features/routine/data/routines_controller.dart';
import '../../features/token/data/token_controller.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'notification_service.dart';

/// Reminder settings + keeps scheduled notifications in sync with the data.
class ReminderController extends ChangeNotifier {
  ReminderController(
    this._prefs, {
    required RoutinesController routines,
    required GallonController gallon,
    required TokenController token,
    required LaundryController laundry,
    required BillsController bills,
    required LocaleController locale,
  })  : _routines = routines,
        _gallon = gallon,
        _token = token,
        _laundry = laundry,
        _bills = bills,
        _locale = locale {
    _enabled = _prefs.getBool('notif_enabled') ?? false;
    _hour = _prefs.getInt('notif_hour') ?? 9;
    _minute = _prefs.getInt('notif_minute') ?? 0;
    _weeklyDigestEnabled = _prefs.getBool('notif_weekly_digest') ?? true;

    _actionSub = NotificationService.instance.onAction.listen((payload) {
      if (payload.startsWith('routine:')) {
        final rId = payload.substring('routine:'.length);
        _routines.markDone(rId);
      }
    });

    _routines.addListener(reschedule);
    _gallon.addListener(reschedule);
    _token.addListener(reschedule);
    _laundry.addListener(reschedule);
    _bills.addListener(reschedule);
    _locale.addListener(reschedule);
  }

  /// Token heads-up: this many days before the predicted run-out.
  static const tokenLeadDays = 3;

  final SharedPreferences _prefs;
  final RoutinesController _routines;
  final GallonController _gallon;
  final TokenController _token;
  final LaundryController _laundry;
  final BillsController _bills;
  final LocaleController _locale;
  StreamSubscription<String>? _actionSub;
  late bool _enabled;
  late int _hour;
  late int _minute;
  late bool _weeklyDigestEnabled;

  bool get enabled => _enabled;
  bool get weeklyDigestEnabled => _weeklyDigestEnabled;
  TimeOfDay get time => TimeOfDay(hour: _hour, minute: _minute);

  Future<void> init() async {
    await NotificationService.instance.init();
    await reschedule();
  }

  /// Returns false if the system permission was denied.
  Future<bool> setEnabled(bool value) async {
    if (value && !await NotificationService.instance.requestPermission()) {
      return false;
    }
    _enabled = value;
    await _prefs.setBool('notif_enabled', value);
    notifyListeners();
    await reschedule();
    return true;
  }

  Future<void> setTime(TimeOfDay t) async {
    _hour = t.hour;
    _minute = t.minute;
    await _prefs.setInt('notif_hour', _hour);
    await _prefs.setInt('notif_minute', _minute);
    notifyListeners();
    await reschedule();
  }

  Future<void> setWeeklyDigestEnabled(bool value) async {
    _weeklyDigestEnabled = value;
    await _prefs.setBool('notif_weekly_digest', value);
    notifyListeners();
    await reschedule();
  }

  List<ReminderItem> _build() {
    final lang = _locale.locale.languageCode;
    final s = AppStrings(Locale(lang));
    final items = <ReminderItem>[
      for (final t in _routines.items)
        ReminderItem(
          'routine_${t.id}',
          t.dueDate,
          s.t('notif_routine', {'name': t.displayName(lang)}),
          actionLabel: s.t('notif_action_done'),
          payload: 'routine:${t.id}',
        ),
    ];
    final g = _gallon.reminderDate;
    if (g != null) items.add(ReminderItem('gallon', g, s.t('notif_gallon')));

    final runOut = _token.forecast().runOutDate;
    if (runOut != null) {
      final d = DateTime(runOut.year, runOut.month, runOut.day - tokenLeadDays);
      items.add(ReminderItem('token', d, s.t('notif_token')));
    }
    for (final o in _laundry.orders) {
      if (o.status == LaundryStatus.droppedOff && o.dueDate != null) {
        items.add(ReminderItem(
          'laundry_${o.id}',
          o.dueDate!,
          s.t('notif_laundry', {'shop': o.shop ?? s.t('laundry_default_shop')}),
        ));
      }
    }
    for (final b in _bills.items) {
      final due = b.nextDue();
      items.add(ReminderItem(
        'bill_${b.id}',
        DateTime(due.year, due.month, due.day - BillsController.leadDays),
        s.t('notif_bill', {'name': b.name}),
      ));
    }
    if (_weeklyDigestEnabled) {
      final now = DateTime.now();
      final daysUntilSunday = (DateTime.sunday - now.weekday + 7) % 7;
      final nextSunday = daysUntilSunday == 0 && (now.hour > _hour || (now.hour == _hour && now.minute >= _minute))
          ? now.add(const Duration(days: 7))
          : now.add(Duration(days: daysUntilSunday));
      items.add(ReminderItem(
        'weekly_digest',
        DateTime(nextSunday.year, nextSunday.month, nextSunday.day),
        s.t('notif_weekly_digest'),
      ));
    }
    return items;
  }

  Future<void> reschedule() async {
    if (!_enabled) {
      await NotificationService.instance.cancelAll();
      return;
    }
    await NotificationService.instance.schedule(_build(), hour: _hour, minute: _minute);
  }

  @override
  void dispose() {
    _actionSub?.cancel();
    super.dispose();
  }
}
