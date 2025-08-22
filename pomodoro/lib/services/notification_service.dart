import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String channelId = 'pomodoro_channel';
  static const String channelName = 'Pomodoro Notifications';
  static const String channelDescription = 'Notifications for Pomodoro timer';
  
  // Throttling variables to prevent notification spam
  static DateTime? _lastNotificationUpdate;
  static const Duration _notificationThrottle = Duration(seconds: 5);

  static Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      enableLights: true,
      ledColor: Colors.red,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap if needed
  }

  static Future<void> showTimerNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    bool force = false,
  }) async {
    // Throttling: only update notification every 1 second for smooth countdown
    if (!force) {
      final now = DateTime.now();
      if (_lastNotificationUpdate != null &&
          now.difference(_lastNotificationUpdate!) < const Duration(seconds: 1)) {
        return; // Skip update if less than 1 second since last update
      }
      _lastNotificationUpdate = now;
    }
    // Calculate progress percentage
    int progressPercentage = ((maxProgress - progress) / maxProgress * 100).round();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      indeterminate: false,
      icon: '@mipmap/ic_launcher',
      silent: true, // No sound for timer progress notifications
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Create new AndroidNotificationDetails with progress
    final AndroidNotificationDetails progressAndroidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercentage,
      indeterminate: false,
      icon: '@mipmap/ic_launcher',
      silent: true, // No sound for timer progress notifications
    );

    final NotificationDetails progressNotificationDetails = NotificationDetails(
      android: progressAndroidDetails,
    );

    await _notifications.show(
      1, // notification ID
      title,
      body,
      progressNotificationDetails,
    );
  }

  static Future<void> showSessionCompleteNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true, // Enable sound for completion notifications
      enableVibration: true,
      autoCancel: true, // Allow user to dismiss this notification
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      2, // notification ID
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> cancelTimerNotification() async {
    await _notifications.cancel(1);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}