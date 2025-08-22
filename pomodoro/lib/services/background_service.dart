import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../models/pomodoro_state.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static Future<void> initialize() async {
    await _instance._initialize();
  }

  static const String _serviceName = 'zendo_pomodoro_service';
  static const String _notificationChannelId = 'zendo_background_service';
  static const String _notificationChannelName = 'ZenDo Background Service';

  Future<void> _initialize() async {
    try {
      print('[BackgroundService] Initializing...');

      // Wait for permission service to be ready
      await PermissionService.initialize();

      // Check if we have alarm permission
      final hasPermission = await PermissionService.hasAlarmPermission();
      print('[BackgroundService] Alarm permission status: $hasPermission');

      await FlutterBackgroundService().configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'pomodoro_timer_channel',
          initialNotificationTitle: 'ZenDo Pomodoro Timer',
          initialNotificationContent: '',
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      print('[BackgroundService] Configured with foreground mode: true');
      print(
          '[BackgroundService] Using notification channel: pomodoro_timer_channel');
      print(
          '[BackgroundService] Initialized successfully with alarm permission: $hasPermission');
    } catch (e) {
      print('[BackgroundService] Error during initialization: $e');
    }
  }

  Future<void> startService() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    print('[BackgroundService] Service running status: $isRunning');

    if (!isRunning) {
      print('[BackgroundService] Starting foreground service...');
      await service.startService();
      print('[BackgroundService] Foreground service started');
    } else {
      print('[BackgroundService] Service already running');
    }
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final notificationService = NotificationService();

    await NotificationService.initialize();

    // Handle service commands
    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // Keep the service alive
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Service is running in foreground
        }
      }
    });
  }
}
