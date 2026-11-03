import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One reminder: show [body] on [date] at the chosen reminder time.
class ReminderItem {
  const ReminderItem(
    this.key,
    this.date,
    this.body, {
    this.actionLabel,
    this.payload,
  });
  final String key;
  final DateTime date;
  final String body;
  final String? actionLabel;
  final String? payload;
}

/// Local (on-device) notifications: no server needed, works offline.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _actionController = StreamController<String>.broadcast();
  Stream<String> get onAction => _actionController.stream;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Falls back to UTC; times may be off but nothing crashes.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _actionController.add(payload);
        }
      },
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final a = await android?.requestNotificationsPermission();
    final i = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return a ?? i ?? false;
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Replaces all scheduled reminders. Dates already in the past get one
  /// nudge at the next reminder time.
  Future<void> schedule(
    List<ReminderItem> items, {
    required int hour,
    required int minute,
  }) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);

    for (final it in items) {
      var at = tz.TZDateTime(
          tz.local, it.date.year, it.date.month, it.date.day, hour, minute);
      if (!at.isAfter(now)) {
        at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: it.key.hashCode & 0x3fffffff,
        title: 'Nesty',
        body: it.body,
        scheduledDate: at,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'nesty_reminders',
            'Nesty reminders',
            channelDescription: 'Reminders for routines, gallon and token',
            actions: it.actionLabel != null
                ? [
                    AndroidNotificationAction(
                      'action_done',
                      it.actionLabel!,
                      showsUserInterface: true,
                    ),
                  ]
                : null,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: it.payload ?? it.key,
        // Inexact = no special "exact alarm" permission needed on Android.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
