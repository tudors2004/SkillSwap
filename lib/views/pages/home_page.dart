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
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search logic if needed
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.black,),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _authService.currentUser?.email ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('drawer.settings'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text('drawer.help'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportPage()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('drawer.logout'.tr()),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
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