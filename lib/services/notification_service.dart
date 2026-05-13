import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo_model.dart';

class TodoNotificationService {
  TodoNotificationService._();

  static final TodoNotificationService instance = TodoNotificationService._();

  static const String _channelId = 'task_reminders';
  static const String _channelName = 'Task reminders';
  static const String _channelDescription = 'Alerts for scheduled todo reminders';
  static const String _importantChannelId = 'task_reminders_important';
  static const String _importantChannelName = 'Task reminders priority';
  static const String _importantChannelDescription =
      'Alerts for scheduled reminders that can bypass Do Not Disturb on Android';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _canUseExactAlarms = false;
  bool _importantReminders = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(_resolveLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings('ic_stat_notification');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _requestPermissions();
    await _configureAndroidChannels();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    final exactAlarmGranted = await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    _canUseExactAlarms = exactAlarmGranted ?? false;

    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> setImportantRemindersEnabled(
    bool enabled,
  ) async {
    _importantReminders = enabled;

    await _configureAndroidChannels();
  }

  Future<bool> scheduleReminder(Todo todo) async {
    if (todo.reminderAt == null || todo.reminderAt!.isBefore(DateTime.now())) {
      return false;
    }

    final scheduledDate = tz.TZDateTime.from(todo.reminderAt!, tz.local);
    final channelId = _currentChannelId();
    final channelName = _currentChannelName();
    final channelDescription = _currentChannelDescription();
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        audioAttributesUsage:
            _importantReminders ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        _notificationIdForTodo(todo.id),
        todo.title,
        todo.description.isNotEmpty ? todo.description : 'Reminder for your task',
        scheduledDate,
        notificationDetails,
        androidScheduleMode:
            _canUseExactAlarms ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelReminder(Todo todo) async {
    try {
      await _plugin.cancel(_notificationIdForTodo(todo.id));
    } catch (_) {
      // Ignore cancellation errors when the notification was never scheduled.
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> _configureAndroidChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      ),
    );

    if (_importantReminders) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          _importantChannelId,
          _importantChannelName,
          description: _importantChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }
  }

  String _currentChannelId() => _importantReminders ? _importantChannelId : _channelId;

  String _currentChannelName() => _importantReminders ? _importantChannelName : _channelName;

  String _currentChannelDescription() =>
      _importantReminders ? _importantChannelDescription : _channelDescription;

  int _notificationIdForTodo(String todoId) {
    final numeric = int.tryParse(todoId);
    if (numeric != null) {
      return numeric.remainder(2147483647);
    }
    return todoId.hashCode & 0x7fffffff;
  }

  tz.Location _resolveLocation(String identifier) {
    const aliases = <String, String>{
      'Asia/Calcutta': 'Asia/Kolkata',
    };

    try {
      return tz.getLocation(identifier);
    } catch (_) {
      final fallback = aliases[identifier];
      if (fallback != null) {
        try {
          return tz.getLocation(fallback);
        } catch (_) {
          // Fall through to UTC.
        }
      }
      return tz.UTC;
    }
  }
}

void _onNotificationTap(NotificationResponse notificationResponse) {}
