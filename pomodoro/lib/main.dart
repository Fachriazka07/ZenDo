import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'page/splashscreen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/permission_service.dart';
import 'models/pomodoro_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_local_notifications
  // This will be handled by NotificationService.initialize()

  // Initialize permission service first
  await PermissionService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize background service
  await BackgroundService.initialize();

  runApp(const PomodoroApp());
}

// Notification action controller for flutter_local_notifications
// Action handling will be implemented in NotificationService

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyLarge: TextStyle(decoration: TextDecoration.none),
          bodyMedium: TextStyle(decoration: TextDecoration.none),
          bodySmall: TextStyle(decoration: TextDecoration.none),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF3E0),
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const PomodoroPage(),
      },
    );
  }
}

enum TimerMode { pomodoro, shortBreak, longBreak }

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  TimerMode currentMode = TimerMode.pomodoro;
  int sessionCount = 0;
  late int totalSeconds;
  late int secondsLeft;
  Timer? timer;
  bool isRunning = false;
  bool isDropdownOpen = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _ambiencePlayer = AudioPlayer();
  String _currentAmbience = 'None';
  bool _isAmbiencePlaying = false;

  // Theme state
  String _currentTheme = 'Caramel Latte';

  // Theme color mappings
  final Map<String, Map<String, Color>> _themeColors = {
    'Caramel Latte': {
      'background': const Color(0xFFFAF3E0),
      'selectTaskBg': const Color(0xFFFAF3E9),
      'navbar': const Color(0xFFFAF3E9),
      'navbarText': const Color(0xFF4A4A4A),
      'navbarActiveIcon': const Color(0xFF7A5C47),
      'navbarInactiveIcon': const Color(0xFFD6C4B3),
      'navbarActiveText': const Color(0xFF7A5C47),
      'navbarInactiveText': const Color(0xFFD6C4B3),
      'buttonActive': const Color(0xFFE0C097),
      'buttonInactive': const Color(0xFFFDF6EC),
      'buttonInactiveOutline': const Color(0xFFE0C097),
      'buttonText': const Color(0xFF4A4A4A),
      'startButton': const Color(0xFFA3B18A),
      'startButtonText': const Color(0xFFFAFAFA),
      'pauseButton': const Color(0xFFE6B17E),
      'continueButton': const Color(0xFFA3B18A),
      'continueButtonText': const Color(0xFFFAFAFA),
      'timerTrack': const Color(0xFFCFC1AA),
      'timerProgress': const Color(0xFFF06C54),
      'timerText': const Color(0xFF4A4A4A),
      'timerCircleBg': const Color(0xFFF7EDE2),
      'dropdownBg': const Color(0xFFFAF3E9),
      'dropdownBorder': const Color(0xFFE0C097),
      'dropdownText': const Color(0xFF4A4A4A),
      'dropdownHover': const Color(0xFFFAF3E0),
      'iconDefault': const Color(0xFF7A5C47),
      'iconActive': const Color(0xFF7A5C47),
      'iconHover': const Color(0xFF7A5C47),
      'iconText': const Color(0xFF4A4A4A),
      'stopButton': const Color(0xFFE5989B),
      // Music overlay specific colors
      'musicOverlayBg': const Color(0xFFFAF3E9),
      'musicOverlayIcon': const Color(0xFFF06C54),
      'musicOverlayText': const Color(0xFF4A4A4A),
      'musicItemBg': const Color(0xFFFFFFFF),
      'musicItemIcon': const Color(0xFFF06C54),
      'musicPlayIcon': const Color(0xFF7A5C47),
      'musicItemText': const Color(0xFF4A4A4A),
      'musicItemHover': const Color(0xFFF5F5F5),
      // Ambience overlay specific colors
      'ambienceOverlayBg': const Color(0xFFFAF3E9),
      'ambienceOverlayIcon': const Color(0xFFF06C54),
      'ambienceOverlayText': const Color(0xFF4A4A4A),
      'ambienceItemBg': const Color(0xFFFFFFFF),
      'ambienceItemIcon': const Color(0xFFF06C54),
      'ambiencePlayIcon': const Color(0xFF7A5C47),
      'ambienceItemText': const Color(0xFF4A4A4A),
      'ambienceItemHover': const Color(0xFFF5F5F5),
    },
    'Ocean Mist': {
      'background': const Color(0xFFE8F0F2),
      'navbar': const Color(0xFF254E58),
      'navbarText': const Color(0xFFE8F0F2),
      'navbarActiveIcon': const Color(0xFFA2D5AB),
      'navbarInactiveIcon': const Color(0xFFE8F0F2),
      'navbarActiveText': const Color(0xFFA2D5AB),
      'navbarInactiveText': const Color(0xFFE8F0F2),
      'buttonActive': const Color(0xFFA2D5AB),
      'buttonInactive': const Color(0xFFC9D6DF),
      'buttonText': const Color(0xFF1C2B2D),
      'startButton': const Color(0xFFA2D5AB),
      'startButtonText': const Color(0xFFFAFAFA),
      'pauseButton': const Color(0xFF88BDBC),
      'continueButton': const Color(0xFFA2D5AB),
      'continueButtonText': const Color(0xFFFAFAFA),
      'timerTrack': const Color(0xFF254E58),
      'timerProgress': const Color(0xFF88BDBC),
      'timerText': const Color(0xFF1C2B2D),
      'dropdownBg': const Color(0xFFC9D6DF),
      'dropdownBorder': const Color(0xFF88BDBC),
      'dropdownText': const Color(0xFF1C2B2D),
      'dropdownHover': const Color(0xFFE8F0F2),
      'iconDefault': const Color(0xFF6E9CA7),
      'iconActive': const Color(0xFFA2D5AB),
      'iconHover': const Color(0xFF88BDBC),
      'iconText': const Color(0xFF1C2B2D),
      'stopButton': const Color(0xFFFFB6B9),
      // Music overlay specific colors
      'musicOverlayBg': const Color(0xFF254E58),
      'musicOverlayIcon': const Color(0xFFA2D5AB),
      'musicOverlayText': const Color(0xFFFAFAFA),
      'musicItemBg': const Color(0xFFC9D6DF),
      'musicItemIcon': const Color(0xFF88BDBC),
      'musicPlayIcon': const Color(0xFFA2D5AB),
      'musicItemText': const Color(0xFF1C2B2D),
      'musicItemHover': const Color(0xFFB5C3CC),
      // Ambience overlay specific colors
      'ambienceOverlayBg': const Color(0xFFE8F0F2),
      'ambienceOverlayIcon': const Color(0xFF6E9CA7),
      'ambienceOverlayText': const Color(0xFF1C2B2D),
      'ambienceItemBg': const Color(0xFFC9D6DF),
      'ambienceItemIcon': const Color(0xFF88BDBC),
      'ambiencePlayIcon': const Color(0xFFA2D5AB),
      'ambienceItemText': const Color(0xFF1C2B2D),
      'ambienceItemHover': const Color(0xFFB5C3CC),
    },
    'Neon Night': {
      'background': const Color(0xFF0D0D0D),
      'navbar': const Color(0xFF1A1A1A),
      'navbarText': const Color(0xFFEAEAEA),
      'navbarActiveIcon': const Color(0xFFFF2E63),
      'navbarInactiveIcon': const Color(0xFFEAEAEA),
      'navbarActiveText': const Color(0xFFFF2E63),
      'navbarInactiveText': const Color(0xFFEAEAEA),
      'buttonActive': const Color(0xFF9D4EDD),
      'buttonInactive': const Color(0xFF2D2D2D),
      'buttonText': const Color(0xFFFFFFFF),
      'startButton': const Color(0xFF08D9D6),
      'startButtonText': const Color(0xFF0D0D0D),
      'continueButton': const Color(0xFF08D9D6),
      'continueButtonText': const Color(0xFF0D0D0D),
      'timerTrack': const Color(0xFF333344),
      'timerProgress': const Color(0xFF9D4EDD),
      'timerText': const Color(0xFFFFFFFF),
      'dropdownBg': const Color(0xFF1A1A1A),
      'dropdownBorder': const Color(0xFF9D4EDD),
      'dropdownText': const Color(0xFFFFFFFF),
      'dropdownHover': const Color(0xFF0D0D0D),
      'iconDefault': const Color(0xFFA259FF),
      'iconActive': const Color(0xFFA259FF),
      'iconHover': const Color(0xFFB983FF),
      'iconText': const Color(0xFFEEEEEE),
      'pauseButton': const Color(0xFFFFB400),
      'stopButton': const Color(0xFFFF4C4C),
      // Music overlay specific colors
      'musicOverlayBg': const Color(0xFF1A1A1D),
      'musicOverlayIcon': const Color(0xFFFF2E63),
      'musicOverlayText': const Color(0xFFEEEEEE),
      'musicItemBg': const Color(0xFF302F4D),
      'musicItemIcon': const Color(0xFFFF2E63),
      'musicPlayIcon': const Color(0xFFFF2E63),
      'musicItemText': const Color(0xFFEEEEEE),
      'musicItemHover': const Color(0xFF3D3B63),
      // Ambience overlay specific colors
      'ambienceOverlayBg': const Color(0xFF1B1B2F),
      'ambienceOverlayIcon': const Color(0xFFA259FF),
      'ambienceOverlayText': const Color(0xFFEEEEEE),
      'ambienceItemBg': const Color(0xFF302F4D),
      'ambienceItemIcon': const Color(0xFFFF2E63),
      'ambiencePlayIcon': const Color(0xFF08D9D6),
      'ambienceItemText': const Color(0xFFEEEEEE),
      'ambienceItemHover': const Color(0xFF3D3B63),
    },
  };

  // Get current theme colors
  Map<String, Color> get _currentThemeColors => _themeColors[_currentTheme]!;

  final List<String> musicFiles = [
    'Cant Take My Eyes off You.mp3',
    'Colorful Flowers.mp3',
    'silent wood.mp3',
    'Jay.mp3',
    'When I Was A Boy.mp3',
    'slowly.mp3',
    'On My Way.mp3',
    'Midnight Stroll.mp3',
    'gingersweet.mp3',
    'Rose.mp3',
    'Midnight Bliss.mp3',
    'Sunflower.mp3',
    'Bake A Pie.mp3',
    'Home.mp3',
  ];

  // Tambahkan state untuk music player
  String? _currentMusic;
  bool _isMusicPlaying = false;

  // AudioPlayer terpisah untuk alarm
  final AudioPlayer _alarmPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    setMode(TimerMode.pomodoro);
    _loadTheme(); // Load saved theme
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_currentMusic != null) {
        _playNextMusic();
      }
    });

    // Notification service will be handled by flutter_local_notifications
    print(
        '[Main] Notification service initialized with flutter_local_notifications');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _alarmPlayer.dispose();
    timer?.cancel();
    super.dispose();
  }

  // Load theme from SharedPreferences
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('selected_theme') ?? 'Caramel Latte';
    setState(() {
      _currentTheme = savedTheme;
    });
  }

  // Save theme to SharedPreferences
  void _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme);
  }

  void setMode(TimerMode mode) {
    setState(() {
      currentMode = mode;
      totalSeconds = _modeDuration(mode);
      secondsLeft = totalSeconds;
      isRunning = false;
      timer?.cancel();
    });
  }

  int _modeDuration(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 1 * 60;
      case TimerMode.shortBreak:
        return 5 * 60;
      case TimerMode.longBreak:
        return 15 * 60;
    }
  }

  void startTimer() async {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft > 0) {
        setState(() => secondsLeft--);
        _updateNotification(); // Update notification every second for countdown
      } else {
        timer?.cancel();
        _handleTimerEnd();
      }
    });
    setState(() => isRunning = true);

    // Show initial timer notification only once when starting
    _updateNotification(force: true);
  }

  void pauseTimer() async {
    timer?.cancel();
    setState(() => isRunning = false);

    // Send pause notification dengan force=true
    _updateNotification(force: true);
  }

  void stopTimer() async {
    timer?.cancel();
    setState(() {
      secondsLeft = totalSeconds;
      isRunning = false;
    });

    // Cancel notification when timer is stopped
    try {
      await NotificationService.cancelTimerNotification();
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  void _handleTimerEnd() async {
    // Play alarm sound
    _playAlarm();

    // Show completion notification with sound
    String completedModeText = '';
    switch (currentMode) {
      case TimerMode.pomodoro:
        completedModeText = 'Pomodoro';
        break;
      case TimerMode.shortBreak:
        completedModeText = 'Short Break';
        break;
      case TimerMode.longBreak:
        completedModeText = 'Long Break';
        break;
    }

    try {
      await NotificationService.showSessionCompleteNotification(
        title: '$completedModeText Completed!',
        body: 'Time to take a break or start the next session.',
      );
    } catch (e) {
      print('Error showing completion notification: $e');
    }

    // Determine next session and update mode
    if (currentMode == TimerMode.pomodoro) {
      sessionCount++;
      if (sessionCount % 4 == 0) {
        setMode(TimerMode.longBreak);
      } else {
        setMode(TimerMode.shortBreak);
      }
    } else {
      setMode(TimerMode.pomodoro);
    }

    // Cancel current timer notification since timer ended
    try {
      await NotificationService.cancelTimerNotification();
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  // Update notification with current timer state using flutter_local_notifications
  void _updateNotification({bool force = false}) {
    try {
      String modeText = '';
      switch (currentMode) {
        case TimerMode.pomodoro:
          modeText = 'Pomodoro';
          break;
        case TimerMode.shortBreak:
          modeText = 'Short Break';
          break;
        case TimerMode.longBreak:
          modeText = 'Long Break';
          break;
      }

      String status = isRunning ? "Running" : "Paused";
      String timeText =
          '${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(secondsLeft % 60).toString().padLeft(2, '0')}';

      // Update notification using flutter_local_notifications
      NotificationService.showTimerNotification(
        title: '$modeText - $status',
        body: 'Time remaining: $timeText',
        progress: secondsLeft,
        maxProgress: _getMaxSeconds(),
        force: force,
      );
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  // Get maximum seconds for current timer mode
  int _getMaxSeconds() {
    return _modeDuration(currentMode);
  }

  void _playAlarm() async {
    // Simpan volume musik saat ini
    double originalMusicVolume = 0.5; // Volume default musik
    bool wasMusicPlaying = _isMusicPlaying;

    // Jika musik sedang berjalan, turunkan volume secara bertahap (fade out)
    if (_isMusicPlaying) {
      for (double volume = originalMusicVolume; volume >= 0.1; volume -= 0.1) {
        await _audioPlayer.setVolume(volume);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // Set volume alarm lebih keras dan mainkan
    await _alarmPlayer.setVolume(1.0); // Volume maksimal
    await _alarmPlayer.play(AssetSource('sounds/alarm.mp3'));

    // Tunggu alarm selesai dengan Future.delayed
    _alarmPlayer.getDuration().then((duration) {
      if (duration != null) {
        Future.delayed(duration, () {
          _restoreMusicVolume(wasMusicPlaying, originalMusicVolume);
        });
      } else {
        // Fallback jika durasi tidak bisa didapat (sekitar 3 detik)
        Future.delayed(const Duration(seconds: 3), () {
          _restoreMusicVolume(wasMusicPlaying, originalMusicVolume);
        });
      }
    });
  }

  // Fungsi untuk mengembalikan volume musik secara bertahap (fade in)
  void _restoreMusicVolume(bool wasMusicPlaying, double originalVolume) async {
    if (wasMusicPlaying) {
      // Pastikan volume dikembalikan ke normal tanpa bergantung pada status _isMusicPlaying
      for (double volume = 0.1; volume <= originalVolume; volume += 0.1) {
        await _audioPlayer.setVolume(volume);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _playMusic(String name) async {
    // Stop ambience if playing to avoid conflict
    if (_isAmbiencePlaying) {
      await _ambiencePlayer.stop();
      setState(() {
        _isAmbiencePlaying = false;
        _currentAmbience = 'None';
      });
    }
    await _audioPlayer.stop(); // Stop current music before playing new
    await _audioPlayer.setVolume(0.5); // Set default volume
    await _audioPlayer.play(AssetSource('sounds/music/$name'));
    setState(() {
      _currentMusic = name;
      _isMusicPlaying = true;
    });
  }

  void _playAmbience(String ambienceName, String ambienceFile) async {
    try {
      if (_currentAmbience == ambienceName && _isAmbiencePlaying) {
        // Stop current ambience
        await _ambiencePlayer.stop();
        setState(() {
          _isAmbiencePlaying = false;
          _currentAmbience = 'None';
        });
      } else {
        // Stop music if playing to avoid conflict
        if (_currentMusic != null) {
          await _audioPlayer.stop();
          setState(() {
            _currentMusic = null;
            _isMusicPlaying = false;
          });
        }
        // Stop current ambience and play new one
        await _ambiencePlayer.stop();
        await _ambiencePlayer
            .play(AssetSource(ambienceFile.replaceFirst('assets/', '')));
        await _ambiencePlayer.setReleaseMode(ReleaseMode.loop);
        setState(() {
          _currentAmbience = ambienceName;
          _isAmbiencePlaying = true;
        });
      }
    } catch (e) {
      print('Error playing ambience: $e');
    }
  }

  void _pauseMusic() async {
    await _audioPlayer.pause();
    setState(() {
      _isMusicPlaying = false;
    });
  }

  void _resumeMusic() async {
    if (_currentMusic != null) {
      await _audioPlayer.play(AssetSource('sounds/music/${_currentMusic!}'));
      setState(() {
        _isMusicPlaying = true;
      });
    }
  }

  void _playNextMusic() {
    if (_currentMusic == null) return;
    final idx = musicFiles.indexOf(_currentMusic!);
    final nextIdx = (idx + 1) % musicFiles.length;
    _playMusic(musicFiles[nextIdx]);
  }

  void _playPrevMusic() {
    if (_currentMusic == null) return;
    final idx = musicFiles.indexOf(_currentMusic!);
    final prevIdx = (idx - 1) < 0 ? musicFiles.length - 1 : idx - 1;
    _playMusic(musicFiles[prevIdx]);
  }

  void _closeMusicPlayer() async {
    await _audioPlayer.stop();
    setState(() {
      _currentMusic = null;
      _isMusicPlaying = false;
    });
  }

  void _showMusicListOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: _currentThemeColors['musicOverlayBg'],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentThemeColors['dropdownBorder'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06C54).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: _currentThemeColors['musicOverlayIcon'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Music',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _currentThemeColors['musicOverlayText'],
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              // Music list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: musicFiles.length,
                  itemBuilder: (context, index) {
                    final name = musicFiles[index];
                    final isSelected = name == _currentMusic;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _currentThemeColors['musicItemHover']
                            : _currentThemeColors['musicItemBg'],
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: _currentThemeColors['musicOverlayIcon']!,
                                width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _currentThemeColors['musicItemBg'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? Icons.music_note : Icons.audiotrack,
                            color: _currentThemeColors['musicItemIcon'],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          name.replaceAll('.mp3', ''),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: _currentThemeColors['musicItemText'],
                            decoration: TextDecoration.none,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: _currentThemeColors['musicOverlayIcon'],
                                size: 24,
                              )
                            : Icon(
                                Icons.play_circle_outline,
                                color: _currentThemeColors['musicPlayIcon'],
                                size: 24,
                              ),
                        onTap: () {
                          _playMusic(name);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    final List<Map<String, dynamic>> themeList = [
      {
        'name': 'Caramel Latte',
        'icon': Icons.coffee,
        'color': const Color(0xFF8B4513),
        'description': 'Sweet & cozy',
      },
      {
        'name': 'Ocean Mist',
        'icon': Icons.waves,
        'color': const Color(0xFF254E58),
        'description': 'Cool ocean breeze',
      },
      {
        'name': 'Neon Night',
        'icon': Icons.nights_stay,
        'color': const Color(0xFF7C3AED),
        'description': 'Dark neon aesthetic',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: _currentThemeColors['dropdownBg'],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentThemeColors['dropdownBorder'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _currentThemeColors['dropdownBg'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: _currentThemeColors['iconActive'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Choose Theme',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _currentThemeColors['dropdownText'],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // Theme list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: themeList.length,
                  itemBuilder: (context, index) {
                    final theme = themeList[index];
                    final isSelected = _currentTheme == theme['name'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        color: isSelected
                            ? _currentThemeColors['buttonActive']
                            : _currentThemeColors['dropdownBg'],
                        border: isSelected
                            ? Border.all(
                                color: _currentThemeColors['dropdownBorder']!,
                                width: 2)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Color preview circle
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: theme['color'],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Theme icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme['color'].withOpacity(0.2),
                                    theme['color'].withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                theme['icon'],
                                color: theme['color'],
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          theme['name'],
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? _currentThemeColors['buttonText']
                                : _currentThemeColors['dropdownText'],
                            fontFamily: 'Poppins',
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          theme['description'],
                          style: TextStyle(
                            color: _currentThemeColors['dropdownText']!
                                .withOpacity(0.7),
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? _currentThemeColors['iconActive']
                              : _currentThemeColors['iconDefault'],
                          size: 24,
                        ),
                        onTap: () {
                          setState(() {
                            _currentTheme = theme['name'];
                          });
                          _saveTheme(theme['name']);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Theme changed to ${theme['name']}',
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                              backgroundColor: theme['color'],
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAmbienceBottomSheet(BuildContext context) {
    final List<Map<String, dynamic>> ambienceList = [
      {
        'name': 'Rain Forest',
        'icon': Icons.forest,
        'color': const Color(0xFF4CAF50),
        'description': 'Peaceful rain sounds',
        'file': 'assets/sounds/ambience/rainforest.mp3'
      },
      {
        'name': 'Ocean Waves',
        'icon': Icons.waves,
        'color': const Color(0xFF2196F3),
        'description': 'Calming ocean sounds',
        'file': 'assets/sounds/ambience/oceanwave.mp3'
      },
      {
        'name': 'Mountain Breeze',
        'icon': Icons.landscape,
        'color': const Color(0xFF795548),
        'description': 'Fresh mountain air',
        'file': 'assets/sounds/ambience/mountainbreeze.mp3'
      },
      {
        'name': 'White Noise',
        'icon': Icons.graphic_eq,
        'color': const Color(0xFF9E9E9E),
        'description': 'Peaceful silence',
        'file': 'assets/sounds/ambience/whitenoise.mp3'
      },
      {
        'name': 'Fireplace',
        'icon': Icons.fireplace,
        'color': const Color(0xFFFF5722),
        'description': 'Warm crackling fire',
        'file': 'assets/sounds/ambience/fireplace.mp3'
      },
      {
        'name': 'Birds Chirping',
        'icon': Icons.pets,
        'color': const Color(0xFFFFEB3B),
        'description': 'Morning bird songs',
        'file': 'assets/sounds/ambience/birdnoise.mp3'
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: _currentThemeColors['ambienceOverlayBg'],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFC1AA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _currentThemeColors['ambienceOverlayIcon']!
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.nature_people,
                        color: _currentThemeColors['ambienceOverlayIcon'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Ambience',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _currentThemeColors['ambienceOverlayText'],
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              // Ambience grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: ambienceList.length,
                  itemBuilder: (context, index) {
                    final ambience = ambienceList[index];
                    final isCurrentlyPlaying =
                        _currentAmbience == ambience['name'] &&
                            _isAmbiencePlaying;
                    return Container(
                      decoration: BoxDecoration(
                        color: isCurrentlyPlaying
                            ? _currentThemeColors['ambienceItemHover']
                            : _currentThemeColors['ambienceItemBg'],
                        borderRadius: BorderRadius.circular(20),
                        border: isCurrentlyPlaying
                            ? Border.all(
                                color:
                                    _currentThemeColors['ambienceOverlayIcon']!,
                                width: 2,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: isCurrentlyPlaying
                                ? _currentThemeColors['ambienceOverlayIcon']!
                                    .withOpacity(0.3)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: isCurrentlyPlaying ? 16 : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            final wasPlaying =
                                _currentAmbience == ambience['name'] &&
                                    _isAmbiencePlaying;
                            _playAmbience(ambience['name'], ambience['file']);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(wasPlaying
                                    ? 'Stopped ${ambience['name']}'
                                    : 'Playing ${ambience['name']}'),
                                backgroundColor: ambience['color'],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color:
                                        _currentThemeColors['ambienceItemBg'],
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _currentThemeColors[
                                                'ambienceItemIcon']!
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        ambience['icon'],
                                        color: _currentThemeColors[
                                            'ambienceItemIcon'],
                                        size: 28,
                                      ),
                                      if (isCurrentlyPlaying)
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: _currentThemeColors[
                                                  'ambienceOverlayBg'],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.pause,
                                              color: _currentThemeColors[
                                                  'ambiencePlayIcon'],
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ambience['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _currentThemeColors['ambienceItemText'],
                                    decoration: TextDecoration.none,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ambience['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _currentThemeColors[
                                        'ambienceItemText']!,
                                    decoration: TextDecoration.none,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (secondsLeft / totalSeconds);

    return AnimatedTheme(
        duration: const Duration(milliseconds: 300),
        data: ThemeData(
          scaffoldBackgroundColor: _currentThemeColors['background'],
        ),
        child: Scaffold(
          backgroundColor: _currentThemeColors['background'],
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20), // hanya padding samping dan bawah
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isDropdownOpen = !isDropdownOpen;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: _currentThemeColors['dropdownBg'],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 24, top: 11, bottom: 11),
                                    child: Text(
                                      "Select Task",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            _currentThemeColors['dropdownText'],
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: 24, top: 14, bottom: 14),
                                    child: AnimatedRotation(
                                      turns: isDropdownOpen ? 0.5 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 24,
                                        color: Color(0xFF4A4A4A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Mode Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildModeButton("Pomodoro", TimerMode.pomodoro),
                              _buildModeButton(
                                  "Short Break", TimerMode.shortBreak),
                              _buildModeButton(
                                  "Long Break", TimerMode.longBreak),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Timer Circle
                          Container(
                            width: 360,
                            height: 360,
                            decoration: BoxDecoration(
                              color: _currentThemeColors['buttonInactive'],
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 332,
                              height: 332,
                              child: CustomPaint(
                                painter: TimerPainter(
                                  progress: secondsLeft / totalSeconds,
                                  baseColor: _currentThemeColors['timerTrack']!,
                                  progressColor:
                                      _currentThemeColors['timerProgress']!,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        formatTime(secondsLeft),
                                        style: TextStyle(
                                          fontFamily: 'Digital7',
                                          fontSize: 100,
                                          color:
                                              _currentThemeColors['timerText'],
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "${sessionCount % 4 + 1} of 4 Sessions",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color:
                                              _currentThemeColors['timerText'],
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Control Buttons
                          if (!isRunning && secondsLeft == totalSeconds)
                            _buildMainButton(
                                "Start",
                                _currentThemeColors['startButton']!,
                                _currentThemeColors['startButtonText']!,
                                startTimer)
                          else if (isRunning)
                            _buildOutlineButton("Pause",
                                _currentThemeColors['pauseButton']!, pauseTimer)
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 160,
                                  child: _buildOutlineButton(
                                      "Stop",
                                      _currentThemeColors['stopButton']!,
                                      stopTimer),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 160,
                                  child: _buildMainButton(
                                      "Start",
                                      _currentThemeColors['continueButton']!,
                                      _currentThemeColors[
                                          'continueButtonText']!,
                                      startTimer),
                                ),
                              ],
                            ),

                          const SizedBox(height: 50),

                          // Icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showThemeBottomSheet(context),
                                  child: _IconWithLabel(
                                      icon: Icons.palette,
                                      label: "Theme",
                                      themeColors: _currentThemeColors),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showMusicListOverlay(context),
                                  child: _IconWithLabel(
                                      icon: Icons.music_note,
                                      label: "Music",
                                      themeColors: _currentThemeColors),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _showAmbienceBottomSheet(context),
                                  child: _IconWithLabel(
                                      icon: Icons.cloud,
                                      label: "Ambience",
                                      themeColors: _currentThemeColors),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Persistent music player above navbar
                if (_currentMusic != null)
                  GestureDetector(
                    onTap: () => _showMusicListOverlay(context),
                    child: MusicPlayerWidget(
                      musicName: _currentMusic!,
                      isPlaying: _isMusicPlaying,
                      onPause: _pauseMusic,
                      onResume: _resumeMusic,
                      onNext: _playNextMusic,
                      onPrev: _playPrevMusic,
                      onClose: _closeMusicPlayer,
                      themeColors: _currentThemeColors,
                    ),
                  ),
                DummyNavbar(themeColors: _currentThemeColors),
              ],
            ),
          ),
        ));
  }

  Widget _buildModeButton(String text, TimerMode mode) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => setMode(mode),
      child: Container(
        width: 120,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? _currentThemeColors['buttonActive']
              : _currentThemeColors['buttonInactive'],
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? null
              : Border.all(color: _currentThemeColors['buttonActive']!),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: _currentThemeColors['buttonText'],
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMainButton(
      String text, Color bgColor, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: 220,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          foregroundColor: textColor,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton(
      String text, Color outlineColor, VoidCallback onPressed) {
    return SizedBox(
      width: 220,
      height: 60,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: outlineColor, width: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: outlineColor,
          ),
        ),
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color progressColor;

  TimerPainter(
      {required this.progress,
      required this.baseColor,
      required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final basePaint = Paint()
      ..color = baseColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw base circle
    canvas.drawCircle(center, radius, basePaint);

    // Draw progress arc
    final sweepAngle = -2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _IconWithLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Map<String, Color> themeColors;

  const _IconWithLabel(
      {required this.icon, required this.label, required this.themeColors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: themeColors['iconDefault']),
        const SizedBox(height: 0),
        Text(label,
            style: TextStyle(
              color: themeColors['iconText'],
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            )),
      ],
    );
  }
}

class DummyNavbar extends StatelessWidget {
  final int activeIndex;
  final Map<String, Color> themeColors;
  const DummyNavbar(
      {super.key, this.activeIndex = 0, required this.themeColors});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.timer,
        'label': 'Pomodoro',
        'active': true,
      },
      {
        'icon': Icons.folder,
        'label': 'Manage',
        'active': false,
      },
      {
        'icon': Icons.bar_chart,
        'label': 'Stats',
        'active': false,
      },
      {
        'icon': Icons.settings,
        'label': 'Setting',
        'active': false,
      },
    ];
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: themeColors['navbar'],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final isActive = i == activeIndex;
          final iconColor = isActive
              ? themeColors['navbarActiveIcon']
              : themeColors['navbarInactiveIcon'];
          final textColor = isActive
              ? themeColors['navbarActiveText']
              : themeColors['navbarInactiveText'];
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(items[i]['icon'] as IconData, color: iconColor, size: 32),
                const SizedBox(height: 6),
                Text(
                  items[i]['label'] as String,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// Persistent music player widget
class MusicPlayerWidget extends StatefulWidget {
  final String musicName;
  final bool isPlaying;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClose;
  final Map<String, Color> themeColors;

  const MusicPlayerWidget({
    super.key,
    required this.musicName,
    required this.isPlaying,
    required this.onPause,
    required this.onResume,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
    required this.themeColors,
  });

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  bool _hoverPrev = false;
  bool _hoverPlay = false;
  bool _hoverNext = false;
  bool _hoverClose = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: widget.themeColors['musicOverlayBg']!,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.musicName.replaceAll('.mp3', ''),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.themeColors['musicOverlayText']!,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverPrev = true),
            onExit: (_) => setState(() => _hoverPrev = false),
            child: IconButton(
              icon: Icon(Icons.skip_previous,
                  color: widget.themeColors['musicOverlayIcon']!),
              onPressed: widget.onPrev,
              tooltip: 'Previous',
            ),
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverPlay = true),
            onExit: (_) => setState(() => _hoverPlay = false),
            child: IconButton(
              icon: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.themeColors['musicOverlayIcon']!,
              ),
              onPressed: widget.isPlaying ? widget.onPause : widget.onResume,
              tooltip: widget.isPlaying ? 'Pause' : 'Resume',
            ),
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverNext = true),
            onExit: (_) => setState(() => _hoverNext = false),
            child: IconButton(
              icon: Icon(Icons.skip_next,
                  color: widget.themeColors['musicOverlayIcon']!),
              onPressed: widget.onNext,
              tooltip: 'Next',
            ),
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverClose = true),
            onExit: (_) => setState(() => _hoverClose = false),
            child: IconButton(
              icon: Icon(Icons.close,
                  color: widget.themeColors['musicOverlayIcon']!),
              onPressed: widget.onClose,
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}
