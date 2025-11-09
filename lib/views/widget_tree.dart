import 'package:flutter/material.dart';
import 'package:skillswap/data/notifiers.dart';
import 'package:skillswap/views/pages/settings_page.dart';
import 'package:skillswap/views/pages/home_page.dart';
import 'package:skillswap/views/pages/login_page.dart';
import 'package:skillswap/views/pages/profile_page.dart';
import 'package:skillswap/views/pages/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


List<Widget> pages = [
  LoginPage(),
  RegisterPage(),
  HomePage(),
  ProfilePage(),
  SettingsPage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
