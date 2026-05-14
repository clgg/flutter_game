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
                const _BrandHeader(),
                const Spacer(flex: 3),
                _ProviderButton(
                  provider: primaryProvider,
                  isPrimary: true,
                  isLoading: _loadingProvider == primaryProvider,
                  onPressed: () => _signIn(primaryProvider),
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  provider: AuthProviderType.facebook,
                  isLoading: _loadingProvider == AuthProviderType.facebook,
                  onPressed: () => _signIn(AuthProviderType.facebook),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _DividerLabel(),
                ),
                OutlinedButton(
                  onPressed:
                      _loadingProvider == null ? widget.onEmailRequested : null,
                  style: _AuthButtonStyles.outlined,
                  child: const Text('Continue with Email'),
                ),
                const SizedBox(height: 20),
                const _LegalFooter(),
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
          const Color(0xFF49D17D).withValues(alpha: 0.26),
          const Color(0xFF49D17D).withValues(alpha: 0),
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
      ..color = const Color(0xFF49D17D).withValues(alpha: 0.08)
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
  const _BrandHeader();

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
            color: const Color(0xFF49D17D).withValues(alpha: 0.12),
            border: Border.all(
              color: const Color(0xFF49D17D).withValues(alpha: 0.42),
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
        const Text(
          'Start your run',
          style: TextStyle(
            color: Color(0xFFE8FFF2),
            fontSize: 34,
            height: 1.05,
            letterSpacing: 0,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sign in to sync progress and rewards.',
          textAlign: TextAlign.center,
          style: TextStyle(
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
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  final AuthProviderType provider;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final label = switch (provider) {
      AuthProviderType.googlePlay => 'Continue with Google Play',
      AuthProviderType.apple => 'Continue with Apple',
      AuthProviderType.facebook => 'Continue with Facebook',
      AuthProviderType.email => 'Continue with Email',
    };

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
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child:
              Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              color: Color(0x99E8FFF2),
              fontSize: 13,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child:
              Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
        ),
      ],
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'By continuing, you agree to the ',
        children: [
          TextSpan(
            text: 'Terms',
            style: TextStyle(color: Color(0xFF49D17D)),
          ),
          TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(color: Color(0xFF49D17D)),
          ),
          TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0x99E8FFF2),
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

class _AuthButtonStyles {
  const _AuthButtonStyles._();

  static ButtonStyle get primary {
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      foregroundColor: const Color(0xFF07130D),
      backgroundColor: const Color(0xFF49D17D),
      disabledBackgroundColor: const Color(0xFF49D17D).withValues(alpha: 0.55),
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
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
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
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
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
