import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isZh => locale.languageCode == 'zh';

  String get appTitle => isZh ? 'ODT 生存' : 'ODT Run';
  String get language => isZh ? '语言' : 'Language';
  String get languageSettings => isZh ? '语言设置' : 'Language';
  String get selectLanguage => isZh ? '选择应用语言' : 'Select app language';
  String get english => isZh ? 'English 英文' : 'English';
  String get chinese => isZh ? '中文' : 'Chinese';
  String get restartNotRequired => isZh ? '立即生效，无需重启' : 'Applies immediately';
  String get character => isZh ? '角色' : 'Character';
  String get weaponLoadout => isZh ? '武器配置' : 'Weapon Loadout';
  String get weaponShop => isZh ? '武器商店' : 'Weapon Shop';
  String get gridView => isZh ? '宫格展示' : 'Grid view';
  String get startRun => isZh ? '开始作战' : 'Start Run';
  String get settingsComingSoon => isZh ? '设置开发中' : 'Settings coming soon';
  String get buyUpgrade => isZh ? '购买 / 升级' : 'Buy / Upgrade';
  String get locked => isZh ? '未拥有' : 'Locked';
  String get select => isZh ? '选择' : 'Select';
  String get close => isZh ? '关闭' : 'Close';
  String get buy => isZh ? '购买' : 'Buy';
  String get upgrade => isZh ? '升级' : 'Upgrade';
  String get notEnoughCoins => isZh ? '金币不足' : 'Not enough coins';
  String purchased(String name) => isZh ? '已购买 $name' : '$name purchased';
  String upgraded(String name) => isZh ? '$name 已升级' : '$name upgraded';
  String lockedWeapon(String name) =>
      isZh ? '$name 尚未拥有' : '$name is not owned';
  String heroLevel(int level) => isZh ? '英雄等级 $level' : 'Hero Lv $level';
  String weaponsCount(int count) =>
      isZh ? '$count 把武器 · 宫格展示' : '$count weapons · Grid view';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((item) => item.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
