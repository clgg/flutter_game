import 'package:flutter/material.dart';

enum AppGameThemeStyle {
  glyph,
  homework,
  zero,
  sticker,
}

class AppGameTheme extends ThemeExtension<AppGameTheme> {
  const AppGameTheme({
    required this.background,
    required this.foreground,
    required this.muted,
    required this.line,
    required this.panel,
    required this.ink,
    required this.accent,
    required this.accent2,
    required this.hot,
    required this.deep,
    required this.glass,
  });

  final Color background;
  final Color foreground;
  final Color muted;
  final Color line;
  final Color panel;
  final Color ink;
  final Color accent;
  final Color accent2;
  final Color hot;
  final Color deep;
  final Color glass;

  static const glyph = AppGameTheme(
    background: Color(0xFF070B0F),
    foreground: Color(0xFFF4F7EF),
    muted: Color(0xFF9CA7A0),
    line: Color(0x26FFFFFF),
    panel: Color(0x0FFFFFFF),
    ink: Color(0xFF07100D),
    accent: Color(0xFFB7FF4A),
    accent2: Color(0xFFFFCF4A),
    hot: Color(0xFFFF5B6F),
    deep: Color(0xFF102319),
    glass: Color(0xC7050D0A),
  );

  static const homework = AppGameTheme(
    background: Color(0xFF0B1020),
    foreground: Color(0xFFFFFAF0),
    muted: Color(0xFFB7C1DB),
    line: Color(0x29FFFFFF),
    panel: Color(0x11FFFFFF),
    ink: Color(0xFF10172A),
    accent: Color(0xFF00D7FF),
    accent2: Color(0xFFFFE45C),
    hot: Color(0xFFFF6A3D),
    deep: Color(0xFF14213D),
    glass: Color(0xD60F172A),
  );

  static const zero = AppGameTheme(
    background: Color(0xFF050611),
    foreground: Color(0xFFF1FBFF),
    muted: Color(0xFF8AA5BE),
    line: Color(0x3D7EF5FF),
    panel: Color(0x0E7EF5FF),
    ink: Color(0xFF061019),
    accent: Color(0xFF7EF5FF),
    accent2: Color(0xFFC6FF3F),
    hot: Color(0xFFFF3B86),
    deep: Color(0xFF0D1430),
    glass: Color(0xDB030712),
  );

  static const sticker = AppGameTheme(
    background: Color(0xFFFFF4D6),
    foreground: Color(0xFF172033),
    muted: Color(0xFF667085),
    line: Color(0x33172033),
    panel: Color(0x8FFFFFFF),
    ink: Color(0xFF172033),
    accent: Color(0xFF1FBF86),
    accent2: Color(0xFFFFBF2F),
    hot: Color(0xFFFF5D5D),
    deep: Color(0xFF283443),
    glass: Color(0xE6FFF8E1),
  );

  static AppGameTheme ofStyle(AppGameThemeStyle style) {
    return switch (style) {
      AppGameThemeStyle.glyph => glyph,
      AppGameThemeStyle.homework => homework,
      AppGameThemeStyle.zero => zero,
      AppGameThemeStyle.sticker => sticker,
    };
  }

  @override
  AppGameTheme copyWith({
    Color? background,
    Color? foreground,
    Color? muted,
    Color? line,
    Color? panel,
    Color? ink,
    Color? accent,
    Color? accent2,
    Color? hot,
    Color? deep,
    Color? glass,
  }) {
    return AppGameTheme(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      panel: panel ?? this.panel,
      ink: ink ?? this.ink,
      accent: accent ?? this.accent,
      accent2: accent2 ?? this.accent2,
      hot: hot ?? this.hot,
      deep: deep ?? this.deep,
      glass: glass ?? this.glass,
    );
  }

  @override
  AppGameTheme lerp(ThemeExtension<AppGameTheme>? other, double t) {
    if (other is! AppGameTheme) {
      return this;
    }
    return AppGameTheme(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      hot: Color.lerp(hot, other.hot, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
    );
  }
}

extension AppGameThemeContext on BuildContext {
  AppGameTheme get gameTheme {
    return Theme.of(this).extension<AppGameTheme>() ?? AppGameTheme.glyph;
  }
}
