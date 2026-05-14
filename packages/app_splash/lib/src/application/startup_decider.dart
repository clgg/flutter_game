class StartupDecider {
  const StartupDecider({
    required this.loginRoute,
  });

  final String loginRoute;

  Future<String> nextRoute() async {
    return loginRoute;
  }
}
