class OfflineEarningsResult {
  final int seconds;
  final double creditsEarned;
  OfflineEarningsResult({required this.seconds, required this.creditsEarned});
}

OfflineEarningsResult computeOffline({
  required DateTime now,
  required DateTime lastSave,
  required double creditsPerSec,
  int maxHours = 12,
}) {
  final rawSeconds = now.difference(lastSave).inSeconds;
  final capSeconds = maxHours * 3600;
  final seconds = rawSeconds.clamp(0, capSeconds);
  final earned = creditsPerSec * seconds;
  return OfflineEarningsResult(seconds: seconds, creditsEarned: earned);
}