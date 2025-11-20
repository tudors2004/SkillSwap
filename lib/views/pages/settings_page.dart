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

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('appearance'.tr()),
          SwitchListTile(
            title: Text('dark_mode'.tr()),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          _buildSectionHeader('general'.tr()),
          ListTile(
            title: Text('language'.tr()),
            subtitle: Text(_getLanguageName(context.locale.languageCode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          SwitchListTile(
            title: Text('notifications'.tr()),
            subtitle: Text('enable_push_notifications'.tr()),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) {
              settingsProvider.setNotificationsEnabled(value);
            },
          ),
          _buildSectionHeader('privacy'.tr()),
          SwitchListTile(
            title: Text('private_account'.tr()),
            subtitle: Text('only_approved_followers'.tr()),
            value: settingsProvider.isAccountPrivate,
            onChanged: (value) {
              settingsProvider.setAccountPrivacy(value);
            },
          ),
          _buildSectionHeader('security'.tr()),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text('change_password'.tr()),
            subtitle: Text('update_password'.tr()),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
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
      default:
        return 'english'.tr();
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: Text('english'.tr()),
              value: const Locale('en'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale>(
              title: Text('french'.tr()),
              value: const Locale('fr'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale>(
              title: Text('german'.tr()),
              value: const Locale('de'),
              groupValue: context.locale,
              onChanged: (value) {
                context.setLocale(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
