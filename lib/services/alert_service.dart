import 'package:flutter/material.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

class AlertService {
  
  // NEW: Instant test to bypass all scheduling logic
  static Future<void> showInstantTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      9999, // Random unique ID
      'System Test Successful! 🎉',
      'Your Med-Lens notifications are officially working!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dosage_channel', 
          'Dosage Alerts',
          channelDescription: 'Reminders to take your medicine',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  // Android 15 Safety Check Helper
  static Future<AndroidScheduleMode> _getScheduleMode() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    // Check if the exact alarm permission is actually granted in system settings
    final bool? canScheduleExact = await androidPlugin?.canScheduleExactNotifications();
    
    if (canScheduleExact == true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    } else {
      debugPrint("Exact alarms blocked by OS. Falling back to inexact mode.");
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  // 1. Schedule a Dosage Reminder
  static Future<void> scheduleDailyReminder(int id, String medName, int hour, int minute) async {
    final scheduleMode = await _getScheduleMode();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Dosage Reminder: $medName',
      'It is time to take your $medName.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dosage_channel', // Channel ID
          'Dosage Alerts',  // Channel Name
          channelDescription: 'Reminders to take your medicine',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode, // Uses the safe mode
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 2. Schedule Expiry Warning
  static Future<void> scheduleExpiryAlert(int id, String medName, DateTime expiryDate) async {
    final alertDate = expiryDate.subtract(const Duration(days: 7));
    
    if (alertDate.isBefore(DateTime.now())) return;

    final scheduleMode = await _getScheduleMode();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id + 1000, 
      'Expiry Warning!',
      'Your $medName will expire in 7 days!',
      tz.TZDateTime.from(alertDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_channel',
          'Expiry Alerts',
          channelDescription: 'Alerts for medicine expiration',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: scheduleMode, // Uses the safe mode
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}