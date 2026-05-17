import 'package:flutter/material.dart';

import '../application/fake_auth_controller.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_session.dart';

class GlobalLoginPage extends StatefulWidget {
  const GlobalLoginPage({
    super.key,
    required this.onSignedIn,
    required this.onEmailRequested,
    this.authController = const FakeAuthController(),
  });

  final ValueChanged<AuthSession> onSignedIn;
  final VoidCallback onEmailRequested;
  final FakeAuthController authController;

  @override
  State<GlobalLoginPage> createState() => _GlobalLoginPageState();
}

class _GlobalLoginPageState extends State<GlobalLoginPage> {
  AuthProviderType? _loadingProvider;

  @override
  Widget build(BuildContext context) {
    final strings = _LoginStrings.of(context);
    final platform = Theme.of(context).platform;
    final primaryProvider = platform == TargetPlatform.iOS
        ? AuthProviderType.apple
        : AuthProviderType.googlePlay;

    return Scaffold(
      body: _AuthScaffold(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                _BrandHeader(strings: strings),
                const Spacer(flex: 3),
                _ProviderButton(
                  provider: primaryProvider,
                  strings: strings,
                  isPrimary: true,
                  isLoading: _loadingProvider == primaryProvider,
                  onPressed: () => _signIn(primaryProvider),
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  provider: AuthProviderType.facebook,
                  strings: strings,
                  isLoading: _loadingProvider == AuthProviderType.facebook,
                  onPressed: () => _signIn(AuthProviderType.facebook),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _DividerLabel(strings: strings),
                ),
                OutlinedButton(
                  onPressed:
                      _loadingProvider == null ? widget.onEmailRequested : null,
                  style: _AuthButtonStyles.outlined,
                  child: Text(strings.provider(AuthProviderType.email)),
                ),
                const SizedBox(height: 20),
                _LegalFooter(strings: strings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(AuthProviderType provider) async {
    if (_loadingProvider != null) {
      return;
    }

    setState(() {
      _loadingProvider = provider;
    });

    final session = await widget.authController.signIn(provider);
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingProvider = null;
    });
    widget.onSignedIn(session);
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF08120E),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _AuthBackgroundPainter(),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = const Color(0xFF102418);
    canvas.drawRect(Offset.zero & size, basePaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF49D17D).withOpacity(0.26),
          const Color(0xFF49D17D).withOpacity(0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.28, size.height * 0.18),
          radius: size.width * 0.72,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.18),
      size.width * 0.72,
      glowPaint,
    );

    final fieldPaint = Paint()
      ..color = const Color(0xFF49D17D).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.18 + i * 0.12);
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.92, y + 26),
        fieldPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.strings});

  final _LoginStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFF49D17D).withOpacity(0.12),
            border: Border.all(
              color: const Color(0xFF49D17D).withOpacity(0.42),
            ),
          ),
          child: const Text(
            'ODT',
            style: TextStyle(
              color: Color(0xFFE8FFF2),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          strings.title,
          style: const TextStyle(
            color: Color(0xFFE8FFF2),
            fontSize: 34,
            height: 1.05,
            letterSpacing: 0,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xBFE8FFF2),
            fontSize: 15,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.strings,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  final AuthProviderType provider;
  final _LoginStrings strings;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final label = strings.provider(provider);

    final icon = switch (provider) {
      AuthProviderType.googlePlay => Icons.play_arrow_rounded,
      AuthProviderType.apple => Icons.phone_iphone_rounded,
      AuthProviderType.facebook => Icons.facebook_rounded,
      AuthProviderType.email => Icons.mail_outline_rounded,
    };

    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: isPrimary ? _AuthButtonStyles.primary : _AuthButtonStyles.filled,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.strings});

  final _LoginStrings strings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.14)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            strings.or,
            style: const TextStyle(
              color: Color(0x99E8FFF2),
              fontSize: 13,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.14)),
        ),
      ],
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.strings});

  final _LoginStrings strings;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: strings.legalPrefix,
        children: [
          TextSpan(
            text: strings.terms,
            style: const TextStyle(color: Color(0xFF49D17D)),
          ),
          TextSpan(text: strings.and),
          TextSpan(
            text: strings.privacy,
            style: const TextStyle(color: Color(0xFF49D17D)),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0x99E8FFF2),
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

class _LoginStrings {
  const _LoginStrings(this.isZh);

  static _LoginStrings of(BuildContext context) {
    return _LoginStrings(Localizations.localeOf(context).languageCode == 'zh');
  }

  final bool isZh;

  String get title => isZh ? '开始作战' : 'Start your run';
  String get subtitle =>
      isZh ? '登录后同步进度和奖励。' : 'Sign in to sync progress and rewards.';
  String provider(AuthProviderType provider) {
    final name = provider.label;
    return isZh ? '使用 $name 继续' : 'Continue with $name';
  }

  String get or => isZh ? '或' : 'or';
  String get legalPrefix =>
      isZh ? '继续即表示你同意' : 'By continuing, you agree to the ';
  String get terms => isZh ? '服务条款' : 'Terms';
  String get and => isZh ? '和' : ' and ';
  String get privacy => isZh ? '隐私政策' : 'Privacy Policy';
}

class _AuthButtonStyles {
  const _AuthButtonStyles._();

  static ButtonStyle get primary {
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      foregroundColor: const Color(0xFF07130D),
      backgroundColor: const Color(0xFF49D17D),
      disabledBackgroundColor: const Color(0xFF49D17D).withOpacity(0.55),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static ButtonStyle get filled {
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: const Color(0xFFE8FFF2),
      backgroundColor: Colors.white.withOpacity(0.12),
      disabledBackgroundColor: Colors.white.withOpacity(0.08),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static ButtonStyle get outlined {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: const Color(0xFFE8FFF2),
      side: BorderSide(color: Colors.white.withOpacity(0.22)),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
