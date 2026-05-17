import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

import '../i18n/app_language_controller.dart';
import '../i18n/app_localizations.dart';
import 'app_theme_controller.dart';
import 'game_feedback_settings_controller.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({
    super.key,
    required this.languageController,
    required this.themeController,
    required this.feedbackSettingsController,
    required this.onCrashLogs,
    required this.onSignOut,
  });

  final AppLanguageController languageController;
  final AppThemeController themeController;
  final GameFeedbackSettingsController feedbackSettingsController;
  final VoidCallback onCrashLogs;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final gameTheme = context.gameTheme;
    return Scaffold(
      backgroundColor: gameTheme.background,
      appBar: AppBar(
        title: Text(strings.isZh ? '设置' : 'Settings'),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('settings_list'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              strings.selectLanguage,
              style: TextStyle(
                color: gameTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.restartNotRequired,
              style: TextStyle(
                color: gameTheme.muted,
                fontSize: 13,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 16),
            _LanguageTile(
              title: strings.english,
              locale: const Locale('en'),
              currentLocale: languageController.locale,
              onSelected: _selectLanguage,
            ),
            const SizedBox(height: 10),
            _LanguageTile(
              title: strings.chinese,
              locale: const Locale('zh'),
              currentLocale: languageController.locale,
              onSelected: _selectLanguage,
            ),
            const SizedBox(height: 24),
            Text(
              strings.isZh ? '主题' : 'Theme',
              style: TextStyle(
                color: gameTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: themeController,
              builder: (context, _) {
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final style in AppGameThemeStyle.values)
                      _ThemeTile(
                        style: style,
                        selected: themeController.style == style,
                        isZh: strings.isZh,
                        onSelected: themeController.setStyle,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              strings.isZh ? '游戏反馈' : 'Game Feedback',
              style: TextStyle(
                color: gameTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: feedbackSettingsController,
              builder: (context, _) {
                return Column(
                  children: [
                    _SettingsSliderTile(
                      icon: feedbackSettingsController.soundVolume <= 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      title: strings.isZh ? '声音' : 'Sound',
                      value: feedbackSettingsController.soundVolume,
                      valueLabel: _percent(
                        feedbackSettingsController.soundVolume,
                      ),
                      onChanged: feedbackSettingsController.setSoundVolume,
                    ),
                    const SizedBox(height: 10),
                    _SettingsSliderTile(
                      icon: Icons.vibration_rounded,
                      title: strings.isZh ? '震动强度' : 'Vibration',
                      value: feedbackSettingsController.vibrationIntensity,
                      valueLabel: _intensityLabel(
                        strings.isZh,
                        feedbackSettingsController.vibrationIntensity,
                      ),
                      onChanged:
                          feedbackSettingsController.setVibrationIntensity,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              strings.isZh ? '诊断' : 'Diagnostics',
              style: TextStyle(
                color: gameTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            _SettingsActionTile(
              icon: Icons.bug_report_rounded,
              title: strings.isZh ? '崩溃日志' : 'Crash logs',
              subtitle: strings.isZh
                  ? '查看、复制或分享本机崩溃信息'
                  : 'View, copy, or share local crash details',
              onTap: onCrashLogs,
            ),
            const SizedBox(height: 24),
            Text(
              strings.isZh ? '账号' : 'Account',
              style: TextStyle(
                color: gameTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            _SettingsActionTile(
              icon: Icons.logout_rounded,
              title: strings.isZh ? '退出账号' : 'Sign out',
              subtitle: strings.isZh
                  ? '清除当前登录状态并返回登录页面'
                  : 'Clear the current session and return to login',
              onTap: () => _confirmSignOut(context),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, Locale locale) {
    languageController.setLocale(locale);
    Navigator.of(context).pop();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.isZh ? '退出账号？' : 'Sign out?'),
          content: Text(
            strings.isZh
                ? '退出后需要重新登录才能继续同步进度。'
                : 'You will need to sign in again to sync progress.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.isZh ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.isZh ? '退出' : 'Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await onSignOut();
    }
  }

  String _percent(double value) {
    return '${(value * 100).round()}%';
  }

  String _intensityLabel(bool isZh, double value) {
    if (value <= 0) {
      return isZh ? '关闭' : 'Off';
    }
    if (value < 0.4) {
      return isZh ? '轻' : 'Low';
    }
    if (value < 0.75) {
      return isZh ? '中' : 'Medium';
    }
    return isZh ? '强' : 'High';
  }
}

class _SettingsSliderTile extends StatelessWidget {
  const _SettingsSliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final double value;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: gameTheme.deep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gameTheme.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: gameTheme.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: gameTheme.foreground,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color: gameTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 4,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final accent = isDestructive ? gameTheme.hot : gameTheme.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: gameTheme.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: gameTheme.foreground,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: gameTheme.muted,
                      fontSize: 12,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: gameTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.style,
    required this.selected,
    required this.isZh,
    required this.onSelected,
  });

  final AppGameThemeStyle style;
  final bool selected;
  final bool isZh;
  final ValueChanged<AppGameThemeStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = AppGameTheme.ofStyle(style);
    return InkWell(
      onTap: () => onSelected(style),
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? theme.accent : theme.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.background, theme.deep, theme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: TextStyle(
                      color: theme.foreground,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _Swatch(color: theme.accent),
                      _Swatch(color: theme.accent2),
                      _Swatch(color: theme.hot),
                      const Spacer(),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: theme.accent,
                          size: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _label {
    if (isZh) {
      return switch (style) {
        AppGameThemeStyle.glyph => '符文绿',
        AppGameThemeStyle.homework => '清新蓝',
        AppGameThemeStyle.zero => '暗夜紫',
        AppGameThemeStyle.sticker => '活力粉',
      };
    }
    return switch (style) {
      AppGameThemeStyle.glyph => 'Glyph',
      AppGameThemeStyle.homework => 'Homework',
      AppGameThemeStyle.zero => 'Zero',
      AppGameThemeStyle.sticker => 'Sticker',
    };
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.locale,
    required this.currentLocale,
    required this.onSelected,
  });

  final String title;
  final Locale locale;
  final Locale currentLocale;
  final void Function(BuildContext context, Locale locale) onSelected;

  @override
  Widget build(BuildContext context) {
    final gameTheme = context.gameTheme;
    final selected = currentLocale.languageCode == locale.languageCode;
    return InkWell(
      onTap: () => onSelected(context, locale),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gameTheme.deep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? gameTheme.accent : gameTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: gameTheme.foreground,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: gameTheme.accent,
              ),
          ],
        ),
      ),
    );
  }
}
