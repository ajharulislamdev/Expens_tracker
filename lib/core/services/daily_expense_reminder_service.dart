import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class DailyExpenseReminderService extends GetxService
    with WidgetsBindingObserver {
  DailyExpenseReminderService(this._settings);

  static const _notificationId = 2109;
  static const _channelId = 'daily_expense_reminder';
  static const _channelName = 'Expense reminders';
  static const _enabledKey = 'expenseReminderEnabled';
  static const _hourKey = 'expenseReminderHour';
  static const _minuteKey = 'expenseReminderMinute';
  static const _defaultTime = TimeOfDay(hour: 21, minute: 0);

  final Box<dynamic> _settings;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final RxBool isEnabled = false.obs;
  final Rx<TimeOfDay> reminderTime = _defaultTime.obs;

  late final Future<void> _ready;
  Object? _initializationError;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      tz_data.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

      final hour = _settings.get(_hourKey);
      final minute = _settings.get(_minuteKey);
      if (hour is int &&
          minute is int &&
          hour >= 0 &&
          hour < 24 &&
          minute >= 0 &&
          minute < 60) {
        reminderTime.value = TimeOfDay(hour: hour, minute: minute);
      }

      isEnabled.value = _settings.get(_enabledKey) == true;
      if (isEnabled.value) {
        await _notifications.cancel(id: _notificationId);
        await _scheduleNext();
      }
    } catch (error, stackTrace) {
      _initializationError = error;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'daily expense reminder',
          context: ErrorDescription('while initializing daily reminders'),
        ),
      );
    }
  }

  Future<void> _ensureReady() async {
    await _ready;
    final error = _initializationError;
    if (error != null) {
      throw StateError('Daily reminders could not initialize: $error');
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    await _ensureReady();
    if (!enabled) {
      await _notifications.cancel(id: _notificationId);
      await _settings.put(_enabledKey, false);
      isEnabled.value = false;
      return true;
    }

    if (!await _requestNotificationPermission()) return false;

    await _settings.put(_enabledKey, true);
    isEnabled.value = true;
    try {
      await _notifications.cancel(id: _notificationId);
      await _scheduleNext();
    } catch (_) {
      isEnabled.value = false;
      await _settings.put(_enabledKey, false);
      rethrow;
    }
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await _ensureReady();
    await _settings.putAll({
      _hourKey: time.hour,
      _minuteKey: time.minute,
    });
    reminderTime.value = time;
    if (isEnabled.value) {
      await _notifications.cancel(id: _notificationId);
      await _scheduleNext();
    }
  }

  Future<bool> _requestNotificationPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        final ios = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      default:
        return false;
    }
  }

  Future<void> _scheduleNext() async {
    final time = reminderTime.value;
    final now = tz.TZDateTime.now(tz.local);
    final nextDate = nextReminderDateTime(
      now,
      hour: time.hour,
      minute: time.minute,
    );
    final scheduledDate = tz.TZDateTime(
      tz.local,
      nextDate.year,
      nextDate.month,
      nextDate.day,
      nextDate.hour,
      nextDate.minute,
    );

    await _notifications.zonedSchedule(
      id: _notificationId,
      title: 'Expense reminder',
      body: 'Take a moment to record today’s expenses.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Daily reminders to record expenses',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> acknowledgeActivity() async {
    await _ensureReady();
    if (!isEnabled.value) return;
    await _notifications.cancel(id: _notificationId);
    await _scheduleNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isEnabled.value) {
      unawaited(_acknowledgeActivityOnResume());
    }
  }

  Future<void> _acknowledgeActivityOnResume() async {
    try {
      await acknowledgeActivity();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'daily expense reminder',
          context: ErrorDescription(
            'while clearing a reminder after the app resumed',
          ),
        ),
      );
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  static DateTime nextReminderDateTime(
    DateTime now, {
    required int hour,
    required int minute,
  }) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (today.isAfter(now)) return today;
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
}
