class GrassGameRuntimeState {
  const GrassGameRuntimeState({
    required this.configVersion,
    required this.isRunning,
  });

  final int configVersion;
  final bool isRunning;

  factory GrassGameRuntimeState.initial({required int configVersion}) {
    return GrassGameRuntimeState(
      configVersion: configVersion,
      isRunning: false,
    );
  }
}
