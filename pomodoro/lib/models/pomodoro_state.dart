enum PomodoroState {
  running,
  paused,
  stopped,
  breakTime,
}

enum SessionType {
  pomodoro,
  shortBreak,
  longBreak,
}

class PomodoroSession {
  final SessionType type;
  final int duration; // in seconds
  final String title;
  final String description;

  const PomodoroSession({
    required this.type,
    required this.duration,
    required this.title,
    required this.description,
  });

  static const PomodoroSession pomodoroSession = PomodoroSession(
    type: SessionType.pomodoro,
    duration: 25 * 60, // 25 minutes
    title: 'Pomodoro',
    description: 'Focus time',
  );

  static const PomodoroSession shortBreakSession = PomodoroSession(
    type: SessionType.shortBreak,
    duration: 5 * 60, // 5 minutes
    title: 'Short Break',
    description: 'Take a short break',
  );

  static const PomodoroSession longBreakSession = PomodoroSession(
    type: SessionType.longBreak,
    duration: 15 * 60, // 15 minutes
    title: 'Long Break',
    description: 'Take a long break',
  );
}

class TimerData {
  final PomodoroState state;
  final SessionType sessionType;
  final int remainingSeconds;
  final int totalSeconds;
  final int pomodoroCount;
  final double progress;

  const TimerData({
    required this.state,
    required this.sessionType,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.pomodoroCount,
    required this.progress,
  });

  TimerData copyWith({
    PomodoroState? state,
    SessionType? sessionType,
    int? remainingSeconds,
    int? totalSeconds,
    int? pomodoroCount,
    double? progress,
  }) {
    return TimerData(
      state: state ?? this.state,
      sessionType: sessionType ?? this.sessionType,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      progress: progress ?? this.progress,
    );
  }
}