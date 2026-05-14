import 'package:app_core/app_core.dart';

class CoreProviders {
  const CoreProviders({
    required this.httpClient,
    required this.keyValueStore,
    required this.analyticsReporter,
    required this.logger,
  });

  final HttpClient httpClient;
  final KeyValueStore keyValueStore;
  final AnalyticsReporter analyticsReporter;
  final AppLogger logger;
}
