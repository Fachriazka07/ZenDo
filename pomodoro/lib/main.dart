import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'page/splashscreen.dart';

void main() {
  runApp(const PomodoroApp());
}

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

  final List<String> musicFiles = [
    'lofi1.mp3',
    'Colorful-Flowers.mp3',
    'silent-wood.mp3',
    'secret.mp3',
  ];

  // Tambahkan state untuk music player
  String? _currentMusic;
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    setMode(TimerMode.pomodoro);
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_currentMusic != null) {
        _playNextMusic();
      }
    });
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
        return 25 * 60;
      case TimerMode.shortBreak:
        return 5 * 60;
      case TimerMode.longBreak:
        return 15 * 60;
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft > 0) {
        setState(() => secondsLeft--);
      } else {
        timer?.cancel();
        _handleTimerEnd();
      }
    });
    setState(() => isRunning = true);
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      secondsLeft = totalSeconds;
      isRunning = false;
    });
  }

  void _handleTimerEnd() async {
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

    await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void _playMusic(String name) async {
    await _audioPlayer.stop(); // Stop current music before playing new
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
        // Stop current ambience and play new one
        await _ambiencePlayer.stop();
        await _ambiencePlayer.play(AssetSource(ambienceFile.replaceFirst('assets/', '')));
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAF3E9),
                Color(0xFFF7EDE2),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
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
                        color: const Color(0xFFF06C54).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Color(0xFFF06C54),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Choose Music',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
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
                            ? const Color(0xFFF06C54).withOpacity(0.1)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: const Color(0xFFF06C54), width: 2)
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
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [const Color(0xFFF06C54), const Color(0xFFFF8A65)]
                                  : [const Color(0xFFCFC1AA), const Color(0xFFE8DCC6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? Icons.music_note : Icons.audiotrack,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          name.replaceAll('.mp3', ''),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected 
                                ? const Color(0xFFF06C54)
                                : const Color(0xFF4A4A4A),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFFF06C54),
                                size: 24,
                              )
                            : const Icon(
                                Icons.play_circle_outline,
                                color: Color(0xFF7A5C47),
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
        'description': 'Focus enhancing sounds',
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAF3E9),
                Color(0xFFF7EDE2),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
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
                        color: const Color(0xFFF06C54).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.nature_people,
                        color: Color(0xFFF06C54),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Choose Ambience',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
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
                     final isCurrentlyPlaying = _currentAmbience == ambience['name'] && _isAmbiencePlaying;
                     return Container(
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                           colors: isCurrentlyPlaying ? [
                             ambience['color'].withOpacity(0.3),
                             ambience['color'].withOpacity(0.1),
                           ] : [
                             Colors.white.withOpacity(0.9),
                             ambience['color'].withOpacity(0.1),
                           ],
                         ),
                         borderRadius: BorderRadius.circular(20),
                         border: isCurrentlyPlaying ? Border.all(
                           color: ambience['color'],
                           width: 2,
                         ) : null,
                         boxShadow: [
                           BoxShadow(
                             color: isCurrentlyPlaying ? 
                               ambience['color'].withOpacity(0.3) : 
                               Colors.black.withOpacity(0.08),
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
                            final wasPlaying = _currentAmbience == ambience['name'] && _isAmbiencePlaying;
                             _playAmbience(ambience['name'], ambience['file']);
                             Navigator.pop(context);
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text(wasPlaying ? 
                                   'Stopped ${ambience['name']}' : 
                                   'Playing ${ambience['name']}'),
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
                                     gradient: LinearGradient(
                                       colors: [
                                         ambience['color'],
                                         ambience['color'].withOpacity(0.7),
                                       ],
                                     ),
                                     borderRadius: BorderRadius.circular(16),
                                     boxShadow: [
                                       BoxShadow(
                                         color: ambience['color'].withOpacity(0.3),
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
                                         color: Colors.white,
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
                                               color: Colors.white,
                                               borderRadius: BorderRadius.circular(8),
                                               boxShadow: [
                                                 BoxShadow(
                                                   color: Colors.black.withOpacity(0.2),
                                                   blurRadius: 4,
                                                   offset: const Offset(0, 2),
                                                 ),
                                               ],
                                             ),
                                             child: Icon(
                                               Icons.pause,
                                               color: ambience['color'],
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A4A4A),
                                    decoration: TextDecoration.none,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ambience['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF7A5C47).withOpacity(0.8),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
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
                            color: const Color(0xFFFAF3E9),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(
                                    left: 24, top: 11, bottom: 11),
                                child: Text(
                                  "Select Task",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF4A4A4A),
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
                                  duration: const Duration(milliseconds: 200),
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
                          _buildModeButton("Short Break", TimerMode.shortBreak),
                          _buildModeButton("Long Break", TimerMode.longBreak),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Timer Circle
                      Container(
                        width: 360,
                        height: 360,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7EDE2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 332,
                          height: 332,
                          child: CustomPaint(
                            painter: TimerPainter(
                              progress: secondsLeft / totalSeconds,
                              baseColor: const Color(0xFFCFC1AA),
                              progressColor: const Color(0xFFF06C54),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    formatTime(secondsLeft),
                                    style: const TextStyle(
                                      fontFamily: 'Digital7',
                                      fontSize: 100,
                                      color: Color(0xFF4A4A4A),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${sessionCount % 4 + 1} of 4 Sessions",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Color(0xFF4A4A4A),
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
                        _buildMainButton("Start", const Color(0xFFA3B18A),
                            const Color(0xFFFAFAFA), startTimer)
                      else if (isRunning)
                        _buildOutlineButton(
                            "Pause", const Color(0xFFE6B17E), pauseTimer)
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              child: _buildOutlineButton(
                                  "Stop", const Color(0xFFE5989B), stopTimer),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 160,
                              child: _buildMainButton(
                                  "Start",
                                  const Color(0xFFA3B18A),
                                  const Color(0xFFFAFAFA),
                                  startTimer),
                            ),
                          ],
                        ),

                      const SizedBox(height: 50),

                      // Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Expanded(
                              child: _IconWithLabel(
                                  icon: Icons.palette, label: "Theme")),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showMusicListOverlay(context),
                              child: const _IconWithLabel(
                                  icon: Icons.music_note, label: "Music"),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showAmbienceBottomSheet(context),
                              child: const _IconWithLabel(
                                  icon: Icons.cloud, label: "Ambience"),
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
                ),
              ),
            const DummyNavbar(),
          ],
        ),
      ),
    );
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
          color: isSelected ? const Color(0xFFE0C097) : const Color(0xFFFDF6EC),
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected ? null : Border.all(color: const Color(0xFFE0C097)),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
              : [],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4A4A4A),
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

  const _IconWithLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7A5C47)),
        const SizedBox(height: 0),
        Text(label,
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
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
  const DummyNavbar({super.key, this.activeIndex = 0});

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
        color: const Color(0xFFFAF3E9),
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
          final iconColor =
              isActive ? const Color(0xFF7A5C47) : const Color(0xFFD6C4B3);
          final textColor =
              isActive ? const Color(0xFF7A5C47) : const Color(0xFFD6C4B3);
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

  const MusicPlayerWidget({
    super.key,
    required this.musicName,
    required this.isPlaying,
    required this.onPause,
    required this.onResume,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
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
        color: const Color(0xFFFAF3E9),
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
              widget.musicName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4A4A),
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
                  color: _hoverPrev
                      ? const Color(0xFFF06C54)
                      : const Color(0xFF7A5C47)),
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
                color: _hoverPlay
                    ? const Color(0xFFF06C54)
                    : const Color(0xFF7A5C47),
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
                  color: _hoverNext
                      ? const Color(0xFFF06C54)
                      : const Color(0xFF7A5C47)),
              onPressed: widget.onNext,
              tooltip: 'Next',
            ),
          ),
          MouseRegion(
            onEnter: (_) => setState(() => _hoverClose = true),
            onExit: (_) => setState(() => _hoverClose = false),
            child: IconButton(
              icon: Icon(Icons.close,
                  color: _hoverClose ? Colors.red : const Color(0xFF7A5C47)),
              onPressed: widget.onClose,
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}
