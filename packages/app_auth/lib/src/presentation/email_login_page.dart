import 'package:flutter/material.dart';

import '../application/fake_auth_controller.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_session.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({
    super.key,
    required this.onSignedIn,
    this.authController = const FakeAuthController(),
  });

  final ValueChanged<AuthSession> onSignedIn;
  final FakeAuthController authController;

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _emailController = TextEditingController(text: 'player@odt.game');
  final _codeController = TextEditingController(text: '000000');
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = _EmailLoginStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF102418),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFE8FFF2),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.title,
                style: const TextStyle(
                  color: Color(0xFFE8FFF2),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.subtitle,
                style: const TextStyle(
                  color: Color(0xBFE8FFF2),
                  fontSize: 15,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 32),
              _AuthTextField(
                controller: _emailController,
                label: strings.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _AuthTextField(
                controller: _codeController,
                label: strings.code,
                keyboardType: TextInputType.number,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isLoading ? null : _signIn,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: const Color(0xFF07130D),
                  backgroundColor: const Color(0xFF49D17D),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.signIn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    final session = await widget.authController.signIn(AuthProviderType.email);
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
    widget.onSignedIn(session);
  }
}

class _EmailLoginStrings {
  const _EmailLoginStrings(this.isZh);

  static _EmailLoginStrings of(BuildContext context) {
    return _EmailLoginStrings(
      Localizations.localeOf(context).languageCode == 'zh',
    );
  }

  final bool isZh;

  String get title => isZh ? '使用邮箱继续' : 'Continue with Email';
  String get subtitle =>
      isZh ? '使用下方演示账号进入游戏。' : 'Use the demo account below to enter the game.';
  String get email => isZh ? '邮箱' : 'Email';
  String get code => isZh ? '验证码' : 'Verification code';
  String get signIn => isZh ? '使用演示数据登录' : 'Sign in with demo data';
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFFE8FFF2)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0x99E8FFF2)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF49D17D)),
        ),
      ),
    );
  }
}
