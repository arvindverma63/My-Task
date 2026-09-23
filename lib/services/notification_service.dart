import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import '../models/appliance_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final dynamic currentTimeZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(currentTimeZone.toString()));
      } catch (e) {
        debugPrint('Error setting local timezone: $e');
      }

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked with payload: ${details.payload}');
        },
      );

      // Create Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'appliance_dues_channel',
        'Appliance & Utility Due Reminders',
        description: 'Notifications for upcoming and due appliance services, LPG cylinder refills, and utility bills',
        importance: Importance.high,
        playSound: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await requestPermissions();
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  int _generateNotificationId(String applianceId) {
    return applianceId.hashCode.abs() % 1000000;
  }

  Future<void> scheduleApplianceDueNotification(Appliance appliance) async {
    if (!_isInitialized) await init();

    final notifId = _generateNotificationId(appliance.id);
    await _notificationsPlugin.cancel(notifId);

    if (!appliance.isDueNotificationEnabled ||
        appliance.dueFrequency == null ||
        appliance.dueFrequency == 'none' ||
        appliance.nextDueDate == null) {
      return;
    }

    final dueDate = appliance.nextDueDate!;
    final reminderDays = appliance.dueReminderDaysBefore;

    // Scheduled time: 9:00 AM on (dueDate - reminderDays)
    final targetDate = dueDate.subtract(Duration(days: reminderDays));
    DateTime scheduledDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      9,
      0,
    );

    final now = DateTime.now();
    if (scheduledDateTime.isBefore(now)) {
      if (dueDate.isAfter(now)) {
        scheduledDateTime = now.add(const Duration(minutes: 5));
      } else {
        // Due date is in the past; no forward schedule
        return;
      }
    }

    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final amountStr = appliance.dueAmount != null && appliance.dueAmount! > 0
        ? ' of ${currencyFmt.format(appliance.dueAmount)}'
        : '';
    final frequencyLabel = appliance.dueFrequency != null && appliance.dueFrequency != 'none'
        ? ' (${appliance.dueFrequency!.toUpperCase()})'
        : '';

    String bodyText;
    if (reminderDays == 0) {
      bodyText = 'Payment$amountStr is due TODAY for ${appliance.name}$frequencyLabel.';
    } else {
      bodyText = 'Payment$amountStr for ${appliance.name}$frequencyLabel is due in $reminderDays day${reminderDays > 1 ? "s" : ""} on ${DateFormat("d MMM yyyy").format(dueDate)}.';
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'appliance_dues_channel',
      'Appliance & Utility Due Reminders',
      channelDescription: 'Notifications for upcoming and due appliance services and utility bills',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(bodyText),
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        notifId,
        '🔔 Due Reminder: ${appliance.name}',
        bodyText,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: appliance.id,
      );
      debugPrint('Scheduled notification for ${appliance.name} at $tzScheduledTime (ID: $notifId)');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelApplianceNotification(String applianceId) async {
    if (!_isInitialized) await init();
    final notifId = _generateNotificationId(applianceId);
    await _notificationsPlugin.cancel(notifId);
  }

  Future<void> rescheduleAll(List<Appliance> appliances) async {
    for (final appliance in appliances) {
      await scheduleApplianceDueNotification(appliance);
    }
  }
}
