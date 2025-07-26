import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:achno/l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // ListTile(
          //   title: Text(l10n.darkMode),
          //   trailing: Switch(
          //     value: themeProvider.isDarkMode,
          //     onChanged: (_) {
          //       themeProvider.toggleTheme();
          //     },
          //   ),
          // ),
          ListTile(
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: languageProvider.locale.languageCode,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.english),
                ),
                DropdownMenuItem(
                  value: 'ar',
                  child: Text(l10n.arabic),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text(l10n.french),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  languageProvider.setLocale(Locale(value));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
