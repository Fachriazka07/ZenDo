/// Utility functions for formatting time
class TimeFormatter {
  /// Formats seconds into MM:SS format
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Formats seconds into a more readable format (e.g., "25 min", "1 hr 30 min")
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${remainingSeconds}s';
    }
  }

  /// Formats progress as percentage
  static String formatProgress(double progress) {
    return '${(progress * 100).toInt()}%';
  }

  /// Converts minutes to seconds
  static int minutesToSeconds(int minutes) {
    return minutes * 60;
  }

  /// Converts seconds to minutes (rounded)
  static int secondsToMinutes(int seconds) {
    return (seconds / 60).round();
  }
}