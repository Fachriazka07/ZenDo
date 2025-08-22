import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pomodoro_state.dart';
import '../utils/format_time.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'pomodoro_timer_channel';
  static const String _channelName = 'Pomodoro Timer';
  static const String _channelDescription =
      'Notifications for Pomodoro timer sessions';
  static const int _notificationId = 1;

  static bool _isInitialized = false;

  // Throttling untuk mencegah spam notifikasi (static variable)
  static DateTime? _lastNotificationUpdate;
  static const Duration _notificationThrottle = Duration(seconds: 5);

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔔 [NotificationService] Starting initialization...');
      await NotificationService()._initialize();
      _isInitialized = true;
      print('🔔 [NotificationService] Initialized successfully');
    } catch (e) {
      print('🔔 [NotificationService] Error during initialization: $e');
    }
  }

  // Action IDs
  static const String actionPause = 'pause';
  static const String actionStart = 'start';
  static const String actionRestart = 'restart';
  static const String actionStop = 'stop';

  Future<void> _initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    print('🔔 Setting up notification callbacks...');
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );
    print('🔔 Notification callbacks registered successfully');

    await _createNotificationChannel();

    // Request notification permissions explicitly
    await _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      print('🔔 [Permissions] Requesting notification permissions...');

      // Request basic notification permission
      final notificationPermission =
          await androidImplementation.requestNotificationsPermission();
      print(
          '🔔 [Permissions] Notification permission granted: $notificationPermission');

      // Request exact alarms permission (important for Xiaomi)
      final exactAlarmsPermission =
          await androidImplementation.requestExactAlarmsPermission();
      print(
          '🔔 [Permissions] Exact alarms permission granted: $exactAlarmsPermission');

      // Check if device is Xiaomi/MIUI and provide specific guidance
      await _checkXiaomiSpecificSettings();
    }
  }

  Future<void> _checkXiaomiSpecificSettings() async {
    // Check if this is a Xiaomi device (basic check)
    print('🔔 [Xiaomi Check] Checking for Xiaomi/MIUI specific settings...');
    print('🔔 [Xiaomi Check] IMPORTANT: If this is a Xiaomi/MIUI device:');
    print('🔔 [Xiaomi Check] 1. Go to Settings → Apps → ZenDo → Notifications');
    print('🔔 [Xiaomi Check] 2. Enable "Show notifications"');
    print('🔔 [Xiaomi Check] 3. Enable "Lock screen notifications"');
    print('🔔 [Xiaomi Check] 4. Go to Settings → Apps → ZenDo → Battery saver');
    print('🔔 [Xiaomi Check] 5. Set to "No restrictions"');
    print('🔔 [Xiaomi Check] 6. Go to Settings → Apps → ZenDo → Autostart');
    print('🔔 [Xiaomi Check] 7. Enable "Autostart"');
    print('🔔 [Xiaomi Check] 8. Add ZenDo to "Protected apps" in Security app');
  }

  Future<void> _createNotificationChannel() async {
    print('[NotificationService] Creating notification channel...');
    print('[NotificationService] Channel ID: $_channelId');
    print('[NotificationService] Channel Name: $_channelName');
    print(
        '[NotificationService] Channel Importance: MAX (for Xiaomi/MIUI compatibility)');

    // Use MAX importance for Xiaomi/MIUI compatibility
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max, // Changed to MAX for Xiaomi
      showBadge: true,
      enableVibration: true,
      playSound: true,
      enableLights: true, // Added for better visibility
      ledColor: Colors.blue, // Added LED color
    );

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      print('[NotificationService] Notification channel created successfully');

      // Check if notifications are enabled (MIUI specific check)
      await _checkNotificationPermissions();
    } else {
      print('[NotificationService] Android implementation not found');
    }
  }

  Future<void> _checkNotificationPermissions() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? areNotificationsEnabled =
          await androidImplementation.areNotificationsEnabled();
      print(
          '[NotificationService] Notifications enabled: $areNotificationsEnabled');

      if (areNotificationsEnabled == false) {
        print('[NotificationService] WARNING: Notifications are disabled!');
        print(
            '[NotificationService] MIUI/Xiaomi users: Go to Settings → Apps → ZenDo → Notifications to enable');
      }
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    print('🔔 === NOTIFICATION RESPONSE RECEIVED ===');
    print('🔔 Action ID: ${response.actionId}');
    print('🔔 Payload: ${response.payload}');
    print('🔔 Notification ID: ${response.id}');
    print('🔔 Input: ${response.input}');

    _handleNotificationAction(response.actionId);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('🔔 === BACKGROUND NOTIFICATION RESPONSE RECEIVED ===');
    print('🔔 Action ID: ${response.actionId}');
    print('🔔 Payload: ${response.payload}');
    print('🔔 Notification ID: ${response.id}');

    _handleNotificationAction(response.actionId);
  }

  static void _handleNotificationAction(String? actionId) {
    if (actionId == null) {
      print('🔔 [ACTION] ❌ Action ID is null');
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    print('🔔 [ACTION] [$timestamp] Processing action: $actionId');

    // Debug: Check if callbacks are set
    print('🔔 [ACTION] DEBUG - Callback status:');
    print(
        '🔔 [ACTION] - onPause: ${NotificationActionHandler.onPause != null}');
    print(
        '🔔 [ACTION] - onStart: ${NotificationActionHandler.onStart != null}');
    print(
        '🔔 [ACTION] - onRestart: ${NotificationActionHandler.onRestart != null}');
    print('🔔 [ACTION] - onStop: ${NotificationActionHandler.onStop != null}');

    // Handle test actions first
    if (actionId.startsWith('test_action_')) {
      print('🔔 [ACTION] ✅ Test action button works! Action: $actionId');
      return;
    }

    switch (actionId) {
      case actionPause:
        print('🔔 [ACTION] >>> CALLING PAUSE CALLBACK <<<');
        if (NotificationActionHandler.onPause != null) {
          try {
            NotificationActionHandler.onPause!.call();
            print('🔔 [ACTION] ✅ Pause callback executed successfully');
          } catch (e) {
            print('🔔 [ACTION] ❌ Error executing pause callback: $e');
          }
        } else {
          print('🔔 [ACTION] ❌ ERROR: Pause callback is null!');
        }
        break;

      case actionStart:
        print('🔔 [ACTION] >>> CALLING START CALLBACK <<<');
        if (NotificationActionHandler.onStart != null) {
          try {
            NotificationActionHandler.onStart!.call();
            print('🔔 [ACTION] ✅ Start callback executed successfully');
          } catch (e) {
            print('🔔 [ACTION] ❌ Error executing start callback: $e');
          }
        } else {
          print('🔔 [ACTION] ❌ ERROR: Start callback is null!');
        }
        break;

      case actionRestart:
        print('🔔 [ACTION] >>> CALLING RESTART CALLBACK <<<');
        if (NotificationActionHandler.onRestart != null) {
          try {
            NotificationActionHandler.onRestart!.call();
            print('🔔 [ACTION] ✅ Restart callback executed successfully');
          } catch (e) {
            print('🔔 [ACTION] ❌ Error executing restart callback: $e');
          }
        } else {
          print('🔔 [ACTION] ❌ ERROR: Restart callback is null!');
        }
        break;

      case actionStop:
        print('🔔 [ACTION] >>> CALLING STOP CALLBACK <<<');
        if (NotificationActionHandler.onStop != null) {
          try {
            NotificationActionHandler.onStop!.call();
            print('🔔 [ACTION] ✅ Stop callback executed successfully');
          } catch (e) {
            print('🔔 [ACTION] ❌ Error executing stop callback: $e');
          }
        } else {
          print('🔔 [ACTION] ❌ ERROR: Stop callback is null!');
        }
        break;

      default:
        print('🔔 [ACTION] ❌ ERROR: Unknown action: $actionId');
        print(
            '🔔 [ACTION] Available actions: $actionPause, $actionStart, $actionRestart, $actionStop');
    }
    print('🔔 ========== END NOTIFICATION ACTION DEBUG ==========');
  }

  Future<void> showPomodoroNotification(TimerData timerData,
      {bool force = false}) async {
    // Throttling: hanya update notifikasi setiap 5 detik untuk mencegah spam
    if (!force) {
      final now = DateTime.now();
      if (_lastNotificationUpdate != null &&
          now.difference(_lastNotificationUpdate!) < _notificationThrottle) {
        print(
            '[NotificationService] THROTTLED - Skipping notification update (last: ${_lastNotificationUpdate}, now: $now)');
        return; // Skip update jika belum 5 detik
      }
      _lastNotificationUpdate = now;
      print(
          '[NotificationService] THROTTLE OK - Updating notification (last: $_lastNotificationUpdate)');
    } else {
      print('[NotificationService] FORCE UPDATE - Bypassing throttle');
    }

    print('[NotificationService] showPomodoroNotification called');
    print('[NotificationService] Notification ID: $_notificationId');
    print('[NotificationService] Channel ID: $_channelId');
    print('[NotificationService] Timer state: ${timerData.state}');
    print(
        '[NotificationService] Remaining seconds: ${timerData.remainingSeconds}');

    // Tukar posisi title dan subtitle - title sekarang dinamis berdasarkan session type
    final String title =
        _getSessionName(timerData.sessionType); // Title dinamis
    final String subtitle =
        '${_getStateName(timerData.state)} - ZenDo'; // Subtitle dengan state
    final String timeText =
        TimeFormatter.formatTime(timerData.remainingSeconds);
    final String body = '$timeText';

    final List<AndroidNotificationAction> actions =
        _getActions(timerData.state);

    print('🔔 Actions to be added: ${actions.length}');
    for (int i = 0; i < actions.length; i++) {
      print('🔔 Action $i: ${actions[i].id} - ${actions[i].title}');
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max, // Changed to MAX for Xiaomi
      priority: Priority.max, // Changed to MAX for Xiaomi
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: (timerData.progress * 100).toInt(),
      icon: '@drawable/ic_clock',
      actions: actions,
      subText: subtitle,
      // Remove large icon for Xiaomi compatibility
      // largeIcon: null,
      // Add specific flags for Xiaomi/MIUI
      fullScreenIntent: false,
      when: DateTime.now().millisecondsSinceEpoch,
      usesChronometer: false,
      chronometerCountDown: false,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: subtitle,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        _notificationId,
        title,
        body,
        notificationDetails,
      );
      print('[NotificationService] Notification shown successfully');
    } catch (e) {
      print('[NotificationService] Error showing notification: $e');
    }
  }

  String _getSubtitle(TimerData timerData) {
    final sessionName = _getSessionName(timerData.sessionType);
    final stateName = _getStateName(timerData.state);
    return '$sessionName - $stateName';
  }

  String _getSessionName(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.pomodoro:
        return 'Pomodoro';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String _getStateName(PomodoroState state) {
    switch (state) {
      case PomodoroState.running:
        return 'Running';
      case PomodoroState.paused:
        return 'Paused';
      case PomodoroState.stopped:
        return 'Stopped';
      case PomodoroState.breakTime:
        return 'Break Time';
      default:
        return 'Unknown';
    }
  }

  List<AndroidNotificationAction> _getActions(PomodoroState state) {
    print('🔔 [_getActions] Creating actions for state: $state');

    switch (state) {
      case PomodoroState.running:
        final actions = [
          const AndroidNotificationAction(
            actionPause,
            'Pause',
            showsUserInterface: false,
            cancelNotification: false,
            // Remove contextual flag to avoid icon requirement
            allowGeneratedReplies: false,
          ),
        ];
        print(
            '🔔 [_getActions] Running state - created ${actions.length} actions');
        return actions;

      case PomodoroState.paused:
        final actions = [
          const AndroidNotificationAction(
            actionStart,
            'Start',
            showsUserInterface: false,
            cancelNotification: false,
            allowGeneratedReplies: false,
          ),
          const AndroidNotificationAction(
            actionRestart,
            'Restart',
            showsUserInterface: false,
            cancelNotification: false,
            allowGeneratedReplies: false,
          ),
          const AndroidNotificationAction(
            actionStop,
            'Stop',
            showsUserInterface: false,
            cancelNotification: false,
            allowGeneratedReplies: false,
          ),
        ];
        print(
            '🔔 [_getActions] Paused state - created ${actions.length} actions');
        return actions;

      case PomodoroState.stopped:
        final actions = [
          const AndroidNotificationAction(
            actionStart,
            'Start',
            showsUserInterface: false,
            cancelNotification: false,
            allowGeneratedReplies: false,
          ),
        ];
        print(
            '🔔 [_getActions] Stopped state - created ${actions.length} actions');
        return actions;

      case PomodoroState.breakTime:
        final actions = [
          const AndroidNotificationAction(
            actionStart,
            'Start',
            showsUserInterface: false,
            cancelNotification: false,
            allowGeneratedReplies: false,
          ),
        ];
        print(
            '🔔 [_getActions] Break time state - created ${actions.length} actions');
        return actions;
    }
  }

  Future<void> showSessionCompleteNotification(
      SessionType completedSession, SessionType nextSession) async {
    final String completedName = _getSessionName(completedSession);
    final String nextName = _getSessionName(nextSession);

    const androidDetails = AndroidNotificationDetails(
      '${_channelId}_complete',
      'Session Complete',
      channelDescription: 'Session completion notifications',
      importance: Importance.max,
      priority: Priority.max,
      autoCancel: true,
      icon: '@drawable/ic_clock',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _notificationId + 1,
      'ZenDo',
      '$completedName finished! Time for $nextName.',
      notificationDetails,
    );

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      cancelSessionCompleteNotification();
    });
  }

  Future<void> cancelNotification() async {
    await _notifications.cancel(_notificationId);
  }

  Future<void> cancelSessionCompleteNotification() async {
    await _notifications.cancel(_notificationId + 1);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Update notification with current timer state
  Future<void> updateNotification({
    required PomodoroState state,
    required SessionType sessionType,
    required int remainingSeconds,
    required int totalSeconds,
    int pomodoroCount = 0,
    bool force = false, // Force update tanpa throttling
  }) async {
    final timerData = TimerData(
      state: state,
      sessionType: sessionType,
      remainingSeconds: remainingSeconds,
      totalSeconds: totalSeconds,
      pomodoroCount: pomodoroCount,
      progress: (totalSeconds - remainingSeconds) / totalSeconds,
    );

    await showPomodoroNotification(timerData, force: force);
  }

  // Test notification method for debugging action buttons
  Future<void> showTestNotification() async {
    print('🔔 [TEST] showTestNotification called');
    print('🔔 [TEST] Test Notification ID: 999');
    print('🔔 [TEST] Channel ID: $_channelId');

    // Create test actions to verify button functionality
    final testActions = [
      const AndroidNotificationAction(
        'test_action_1',
        'Test 1',
        showsUserInterface: false,
        cancelNotification: false,
        allowGeneratedReplies: false,
      ),
      const AndroidNotificationAction(
        'test_action_2',
        'Test 2',
        showsUserInterface: false,
        cancelNotification: false,
        allowGeneratedReplies: false,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      autoCancel: false,
      showWhen: true,
      ongoing: false,
      actions: testActions,
      when: DateTime.now().millisecondsSinceEpoch,
      fullScreenIntent: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        999, // Different ID for test
        'ZenDo Action Test',
        'Tap Test 1 or Test 2 buttons to verify action functionality',
        notificationDetails,
      );
      print('🔔 [TEST] Test notification with actions shown successfully');
      print('🔔 [TEST] Actions count: ${testActions.length}');
    } catch (e) {
      print('🔔 [TEST] Error showing test notification: $e');
    }
  }

  // Method to test if notification actions work on Xiaomi devices
  Future<void> testXiaomiActionButtons() async {
    print(
        '🔔 [XIAOMI TEST] Testing action buttons specifically for Xiaomi/MIUI...');

    // Show a simple test notification with action buttons
    await showTestNotification();

    print('🔔 [XIAOMI TEST] Test notification sent.');
    print('🔔 [XIAOMI TEST] Please tap the Test 1 or Test 2 buttons.');
    print('🔔 [XIAOMI TEST] Check logcat for action response logs.');
  }
}

// Callback handler for notification actions
class NotificationActionHandler {
  static VoidCallback? onPause;
  static VoidCallback? onStart;
  static VoidCallback? onRestart;
  static VoidCallback? onStop;

  static void setCallbacks({
    VoidCallback? pause,
    VoidCallback? start,
    VoidCallback? restart,
    VoidCallback? stop,
  }) {
    onPause = pause;
    onStart = start;
    onRestart = restart;
    onStop = stop;
  }
}
