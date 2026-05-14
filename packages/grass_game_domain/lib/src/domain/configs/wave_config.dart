class WaveConfig {
  const WaveConfig({
    required this.startSecond,
    required this.enemyId,
    required this.spawnIntervalSeconds,
  });

  final int startSecond;
  final String enemyId;
  final double spawnIntervalSeconds;
}
