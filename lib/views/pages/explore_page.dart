import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:skillswap/services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/services/connection_service.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';

//TODO: The user cards are not showing the skills, only the nationality - needs update
//TODO: The filter compatible only doesnt work
//TODO: LINIA 627

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  Map<String, dynamic>? _myProfile;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = true;
  bool _showCompatibleOnly = false;

  final _categories = [
    'explore_page.category_all',
    'explore_page.category_programming',
    'explore_page.category_languages',
    'explore_page.category_music',
    'explore_page.category_art',
    'explore_page.category_cooking',
  ];

  String _selectedCategory = 'explore_page.category_all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _listenToUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _usersSubscription?.cancel();
    super.dispose();
  }

  void _listenToUsers() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      final users = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        if (doc.id == currentUser.uid) continue;

        final data = doc.data();
        users.add({
          'uid': doc.id,
          ...data,
        });
      }

      if (mounted) {
        setState(() {
          _allUsers = users;
        });
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final profile = await _profileService.getProfile();
      final users = await _fetchAllUsers();

      if (mounted) {
        setState(() {
          _myProfile = profile;
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final users = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        if (doc.id == currentUser.uid) continue;

        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        users.add({
          'uid': doc.id,
          ...data,
        });
      }

      return users;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_myProfile == null && !_isLoadingUsers) {
      _loadData();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'explore_page.search_hint'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
        ),

        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = cat == _selectedCategory;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        if (_myProfile != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('explore_page.filter_label'.tr(), style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                FilterChip(
                  label: Text('explore_page.compatible_only'.tr()),
                  selected: _showCompatibleOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showCompatibleOnly = selected;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: 'explore_page.tab_people'.tr()),
            Tab(text: 'explore_page.tab_skills'.tr()),
            Tab(text: 'explore_page.tab_events'.tr()),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPeopleTab(),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _checkCompatibility(Map<String, dynamic> otherUser) {
    if (_myProfile == null) {
      return {'isCompatible': true, 'reasons': []};
    }

    final myPrefs = _myProfile!['preferences'] as Map<String, dynamic>?;
    final reasons = <String>[];

    if (myPrefs == null) {
      return {'isCompatible': true, 'reasons': []};
    }

    if (myPrefs['gender'] != null &&
        myPrefs['gender'] != 'Any' &&
        otherUser['gender'] != myPrefs['gender']) {
      reasons.add('explore_page.gender_mismatch'.tr(namedArgs: {
        'expected': myPrefs['gender'],
        'found': otherUser['gender']
      }));
    }

    if (myPrefs['nationality'] != null &&
        myPrefs['nationality'] != 'Any' &&
        otherUser['nationality'] != myPrefs['nationality']) {
      reasons.add('explore_page.nationality_mismatch'.tr(namedArgs: {
        'expected': myPrefs['nationality'],
        'found': otherUser['nationality']
      }));
    }

    if (myPrefs['locationRange'] != null &&
        _myProfile!['location'] != null &&
        otherUser['location'] != null) {
      try {
        final distance = _calculateDistance(
          _myProfile!['location'],
          otherUser['location'],
        );

        if (distance > (myPrefs['locationRange'] as num)) {
          reasons.add('explore_page.too_far'.tr(namedArgs: {
            'distance': distance.toStringAsFixed(0),
            'limit': myPrefs['locationRange'].toString()
          }));
        }
      } catch (e) {
        print('Error calculating distance: $e');
      }
    }

    if (myPrefs['ageRange'] != null && otherUser['dateOfBirth'] != null) {
      try {
        final age = _calculateAge(otherUser['dateOfBirth']);
        final ageRangeMap = myPrefs['ageRange'] as Map<String, dynamic>;
        final min = (ageRangeMap['min'] as num?)?.toInt() ?? 18;
        final max = (ageRangeMap['max'] as num?)?.toInt() ?? 100;

        if (age < min || age > max) {
          reasons.add('explore_page.age_outside_range'.tr(namedArgs: {
            'age': age.toString(),
            'min': min.toString(),
            'max': max.toString()
          }));
        }
      } catch (e) {
        print('Error checking age: $e');
      }
    }

    if (myPrefs['religion'] != null &&
        myPrefs['religion'] != 'Any' &&
        otherUser['religion'] != null &&
        otherUser['religion'] != myPrefs['religion']) {
      reasons.add('explore_page.religion_preference'.tr(namedArgs: {
        'expected': myPrefs['religion'],
        'found': otherUser['religion']
      }));
    }

    return {
      'isCompatible': reasons.isEmpty,
      'reasons': reasons,
    };
  }

  int _calculateAge(dynamic dateOfBirth) {
    DateTime dob;

    if (dateOfBirth is Timestamp) {
      dob = dateOfBirth.toDate();
    } else if (dateOfBirth is String) {
      dob = DateTime.parse(dateOfBirth);
    } else {
      throw Exception('Invalid date format');
    }

    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  double _calculateDistance(dynamic loc1, dynamic loc2) {
    const R = 6371;

    double lat1, lon1, lat2, lon2;

    if (loc1 is GeoPoint) {
      lat1 = loc1.latitude;
      lon1 = loc1.longitude;
    } else if (loc1 is Map<String, dynamic>) {
      lat1 = loc1['latitude'] as double;
      lon1 = loc1['longitude'] as double;
    } else {
      throw Exception('Invalid location format for loc1');
    }

    if (loc2 is GeoPoint) {
      lat2 = loc2.latitude;
      lon2 = loc2.longitude;
    } else if (loc2 is Map<String, dynamic>) {
      lat2 = loc2['latitude'] as double;
      lon2 = loc2['longitude'] as double;
    } else {
      throw Exception('Invalid location format for loc2');
    }

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }


  Widget _buildPeopleTab() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allUsers.isEmpty) {
      return Center(
        child: Text('explore_page.no_users_found'.tr()),
      );
    }

    var filteredUsers = _allUsers.where((user) {
      if (_searchQuery.isNotEmpty) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final skills = (user['skills'] as List?)?.join(' ').toLowerCase() ?? '';
        if (!name.contains(_searchQuery) && !skills.contains(_searchQuery)) {
          return false;
        }
      }

      if (_selectedCategory != 'explore_page.category_all') {
        final skills = (user['skills'] as List?)?.cast<String>() ?? [];
        final categoryName = _selectedCategory.split('.').last.replaceAll('category_', '');
        if (!skills.any((s) => s.toLowerCase().contains(categoryName.toLowerCase()))) {
          return false;
        }
      }

      return true;
    }).toList();

    filteredUsers.sort((a, b) {
      final compatA = _checkCompatibility(a)['isCompatible'] as bool;
      final compatB = _checkCompatibility(b)['isCompatible'] as bool;
      if (compatA && !compatB) return -1;
      if (!compatA && compatB) return 1;
      return 0;
    });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final compatibility = _checkCompatibility(user);
        return _buildUserCard(user, compatibility);
      },
    );
  }
  Widget _buildUserCard(Map<String, dynamic> user, Map<String, dynamic> compatibility) {
    final isCompatible = compatibility['isCompatible'] as bool;
    final reasons = compatibility['reasons'] as List<String>;
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompatible ? theme.colorScheme.primary.withOpacity(0.3) : Colors.red,
          width: isCompatible ? 1 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showCompatibilityDialog(user, compatibility),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user['profilePictureBase64'] != null
                        ? MemoryImage(base64Decode(user['profilePictureBase64']))
                        : null,
                    child: user['profilePictureBase64'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCompatible ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        isCompatible ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'explore_page.unknown'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'explore_page.teaches'.tr(namedArgs: {
                        'skills': (user['skills'] as List?)?.take(2).join(', ') ?? 'explore_page.na'.tr()
                      }),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user['nationality'] ?? 'explore_page.unknown_location'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    if (!isCompatible) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reasons.length == 1
                            ? 'explore_page.incompatibility_issues'.tr(namedArgs: {'count': reasons.length.toString()})
                            : 'explore_page.incompatibility_issues_plural'.tr(namedArgs: {'count': reasons.length.toString()}),
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: isCompatible ? null : Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompatibilityDialog(Map<String, dynamic> user, Map<String, dynamic> compatibility) async {
    final isCompatible = compatibility['isCompatible'] as bool;
    final reasons = compatibility['reasons'] as List<String>;
    final connectionService = ConnectionService();
    final status = await connectionService.getConnectionStatus(user['uid']);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCompatible ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isCompatible ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isCompatible ? 'explore_page.compatible_match'.tr() : 'explore_page.compatibility_issues'.tr(),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'] ?? 'explore_page.unknown'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text('${user['nationality']} • ${(user['skills'] as List?)?.join(', ') ?? 'explore_page.no_skills'.tr()}'),
              const SizedBox(height: 16),
              if (isCompatible) ...[
                Text('explore_page.match_all_preferences'.tr()),
                Text('explore_page.location_within_range'.tr()),
                Text('explore_page.profile_meets_criteria'.tr()),
              ] else ...[
                Text(
                  'explore_page.issues_found'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 8),
                ...reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(reason, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('explore_page.close'.tr()),
          ),
          if (status == null)
            ElevatedButton(
              onPressed: () async {
                await connectionService.sendConnectionRequest(user['uid']);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('explore_page.connection_request_sent'.tr())),
                  );
                }
              },
              child: Text('explore_page.connect'.tr()),
            )
          else if (status == 'pending')
            ElevatedButton(
              onPressed: null,
              child: Text('explore_page.pending'.tr()),
            )
          else if (status == 'accepted')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: NAVIGATE TO THE CHAT !!!
                },
                child: Text('explore_page.chat'.tr()),
              ),
        ],
      ),
    );
  }

}
