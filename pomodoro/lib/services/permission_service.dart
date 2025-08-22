import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        print('[PermissionService] Initializing for Android');

        // Check and request alarm permission for Android 12+
        await _checkAlarmPermission();
      }

      _isInitialized = true;
      print('[PermissionService] Initialized successfully');
    } catch (e) {
      print('[PermissionService] Error during initialization: $e');
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  static Future<void> _checkAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      print('[PermissionService] Current alarm permission status: $status');

      if (status.isDenied) {
        print('[PermissionService] Requesting alarm permission...');
        final result = await Permission.scheduleExactAlarm.request();
        print('[PermissionService] Alarm permission request result: $result');

        if (result.isGranted) {
          print('[PermissionService] Alarm permission granted');
        } else {
          print(
              '[PermissionService] Alarm permission denied - app will use fallback mode');
        }
      } else if (status.isGranted) {
        print('[PermissionService] Alarm permission already granted');
      }
    } catch (e) {
      print('[PermissionService] Error checking alarm permission: $e');
    }
  }

  static Future<bool> hasAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      print('[PermissionService] Error checking alarm permission: $e');
      return false;
    }
  }
}
