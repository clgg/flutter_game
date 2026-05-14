import '../domain/auth_provider_type.dart';
import '../domain/auth_session.dart';

class FakeAuthController {
  const FakeAuthController();

  Future<AuthSession> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return AuthSession(
      userId: 'fake_${provider.name}_user',
      displayName: 'ODT Player',
      provider: provider,
    );
  }
}
