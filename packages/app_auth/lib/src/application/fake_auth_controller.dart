import '../domain/auth_provider_type.dart';
import '../domain/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthController {
  const FakeAuthController();

  static const _signedInKey = 'app_auth.fake_signed_in';
  static const _providerKey = 'app_auth.fake_provider';

  Future<AuthSession> signIn(AuthProviderType provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final session = AuthSession(
      userId: 'fake_${provider.name}_user',
      displayName: 'ODT Player',
      provider: provider,
    );
    await _saveSession(session);
    return session;
  }

  Future<bool> hasSignedInSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_signedInKey) ?? false;
  }

  Future<void> _saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedInKey, true);
    await prefs.setString(_providerKey, session.provider.name);
  }
}
