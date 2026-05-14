abstract interface class AnalyticsReporter {
  void report(String eventName, Map<String, Object?> params);
}
