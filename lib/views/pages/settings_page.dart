import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skillswap/providers/theme_provider.dart';
import 'package:skillswap/providers/settings_provider.dart';
import 'package:skillswap/views/pages/change_password_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'appearance'.tr()),
          SwitchListTile(
            title: Text('dark_mode'.tr(), style: theme.textTheme.titleMedium),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: theme.colorScheme.primary,
          ),
          _buildSectionHeader(context, 'general'.tr()),
          ListTile(
            title: Text('language'.tr(), style: theme.textTheme.titleMedium),
            subtitle: Text(_getLanguageName(context.locale.languageCode), style: theme.textTheme.bodyMedium),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          SwitchListTile(
            title: Text('notifications'.tr(), style: theme.textTheme.titleMedium),
            subtitle: Text('enable_push_notifications'.tr(), style: theme.textTheme.bodyMedium),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) {
              settingsProvider.setNotificationsEnabled(value);
            },
             activeColor: theme.colorScheme.primary,
          ),
          _buildSectionHeader(context, 'privacy'.tr()),
          SwitchListTile(
            title: Text('private_account'.tr(), style: theme.textTheme.titleMedium),
            subtitle: Text('only_approved_followers'.tr(), style: theme.textTheme.bodyMedium),
            value: settingsProvider.isAccountPrivate,
            onChanged: (value) {
              settingsProvider.setAccountPrivacy(value);
            },
             activeColor: theme.colorScheme.primary,
          ),
          _buildSectionHeader(context, 'security'.tr()),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text('change_password'.tr(), style: theme.textTheme.titleMedium),
            subtitle: Text('update_password'.tr(), style: theme.textTheme.bodyMedium),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'english'.tr();
      case 'fr':
        return 'french'.tr();
      case 'de':
        return 'german'.tr();
      case 'es':
        return 'spanish'.tr();
      case 'it':
        return 'italian'.tr();
      case 'ar':
        return 'arabic'.tr();
      case 'ro':
        return 'romanian'.tr();
      case 'pt':
        return 'portuguese'.tr();
      default:
        return 'english'.tr();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_language'.tr()),
        titleTextStyle: theme.textTheme.titleLarge,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: Text('english'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('en'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
               activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<Locale>(
              title: Text('french'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('fr'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
               activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<Locale>(
              title: Text('german'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('de'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
               activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<Locale>(
              title: Text('spanish'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('es'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<Locale>(
              title: Text('italian'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('it'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<Locale>(
              title: Text('arabic'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('ar'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<Locale>(
              title: Text('romanian'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('ro'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<Locale>(
              title: Text('portuguese'.tr(), style: theme.textTheme.titleMedium),
              value: const Locale('pt'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                settingsProvider.setLanguage(value.languageCode);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
