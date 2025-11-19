import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/providers/theme_provider.dart';
import 'package:skillswap/providers/settings_provider.dart';
import 'package:skillswap/views/pages/change_password_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
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
        return 'English';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }


}
