import 'auth_provider_type.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    required this.provider,
  });

  final String userId;
  final String displayName;
  final AuthProviderType provider;
}
