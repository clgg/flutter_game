enum AuthProviderType {
  googlePlay,
  apple,
  facebook,
  email,
}

extension AuthProviderTypeLabel on AuthProviderType {
  String get label {
    return switch (this) {
      AuthProviderType.googlePlay => 'Google Play',
      AuthProviderType.apple => 'Apple',
      AuthProviderType.facebook => 'Facebook',
      AuthProviderType.email => 'Email',
    };
  }
}
