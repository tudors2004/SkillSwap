import 'package:flutter/material.dart';
import 'package:skillswap/services/auth_service.dart';
import 'package:skillswap/views/pages/login_page.dart';
import 'package:skillswap/views/pages/settings_page.dart';
import 'package:skillswap/views/pages/profile_page.dart';
import 'package:skillswap/views/pages/skills_page.dart';
import 'package:skillswap/views/pages/explore_page.dart';
import 'package:skillswap/views/pages/wallet_page.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/providers/settings_provider.dart';
import 'package:skillswap/providers/theme_provider.dart';
import 'package:skillswap/services/connection_service.dart';
import 'package:skillswap/views/pages/notifications_page.dart';
import 'package:skillswap/views/pages/chat_list_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:skillswap/views/pages/help_support_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final ConnectionService _connectionService = ConnectionService();
  int _selectedIndex = 0;

  // We have exactly 5 pages here
  final List<Widget> _pages = [
    const ExplorePage(),   // Index 0: Home is now Explore
    const WalletPage(),    // Index 1: Wallet
    const SkillsPage(),    // Index 2: Skills
    const ChatListPage(),  // Index 3: Chat
    const ProfilePage(),   // Index 4: Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      settingsProvider.syncFromCloud();
      themeProvider.syncFromCloud();
    });
  }

  Future<void> _handleLogout() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    await settingsProvider.clearData();
    await themeProvider.clearData();

    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDestructive
        ? Colors.red.shade400
        : (isDarkMode ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color);

    final iconColor = isDestructive
        ? Colors.red.shade400
        : (isDarkMode ? Colors.white : Theme.of(context).primaryColor);

    final color = isDestructive
        ? Colors.red.shade400
        : Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDestructive ? Colors.red : Theme.of(context).primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: textColor?.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap'),
        actions: [
          StreamBuilder<int>(
            stream: _connectionService.getUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).colorScheme.surface,
              ],
              stops: const [0.0, 0.3, 0.5],
            ),
          ),
          child: Column(
            children: [
              // Custom Header with gradient overlay
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _authService.currentUser?.displayName ?? 'Welcome!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _authService.currentUser?.email ?? 'User',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      title: 'drawer.settings'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      activeIcon: Icons.help,
                      title: 'drawer.help'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportPage()));
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Divider(),
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout_outlined,
                      activeIcon: Icons.logout,
                      title: 'drawer.logout'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              // Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'SkillSwap © 2025',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // We explicitly access the page by index
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        // Exactly 5 items to match the 5 pages in _pages
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined), // Home Icon
            activeIcon: const Icon(Icons.home),
            label: 'bottomNav.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: 'bottomNav.wallet'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            activeIcon: const Icon(Icons.library_books),
            label: 'bottomNav.mySkills'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: 'bottomNav.chat'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'bottomNav.profile'.tr(),
          ),
        ],
      ),
    );
  }
}