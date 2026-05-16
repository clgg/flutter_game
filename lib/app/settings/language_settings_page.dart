import 'package:flutter/material.dart';

import '../i18n/app_language_controller.dart';
import '../i18n/app_localizations.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({
    super.key,
    required this.languageController,
  });

  final AppLanguageController languageController;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF07130D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07130D),
        foregroundColor: const Color(0xFFE8FFF2),
        title: Text(strings.languageSettings),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              strings.selectLanguage,
              style: const TextStyle(
                color: Color(0xFFE8FFF2),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.restartNotRequired,
              style: const TextStyle(
                color: Color(0x99E8FFF2),
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
          ],
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, Locale locale) {
    languageController.setLocale(locale);
    Navigator.of(context).pop();
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
    final selected = currentLocale.languageCode == locale.languageCode;
    return InkWell(
      onTap: () => onSelected(context, locale),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF102418),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF49D17D) : const Color(0x3349D17D),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFE8FFF2),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF49D17D),
              ),
          ],
        ),
      ),
    );
  }
}
