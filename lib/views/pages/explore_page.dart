import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:skillswap/services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillswap/services/connection_service.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:skillswap/data/constants.dart';
import 'package:skillswap/views/pages/chat_list_page.dart';

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

  // Use Constants for Categories (lowercase internal IDs)
  String _selectedCategory = 'all';

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
        .listen((snapshot) async {
      final users = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        if (doc.id == currentUser.uid) continue;

        final data = doc.data();

        // Fetch skills from subcollection (like wallet_page does)
        List<Map<String, dynamic>> skills = [];
        List<Map<String, dynamic>> skillsToLearn = [];

        try {
          final skillsDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .collection('skills')
              .doc('userSkills')
              .get();

          if (skillsDoc.exists) {
            final skillsData = skillsDoc.data();
            if (skillsData != null) {
              // Parse skillsToOffer
              final skillsToOfferRaw = skillsData['skillsToOffer'];
              if (skillsToOfferRaw is List) {
                skills = skillsToOfferRaw.map((e) {
                  if (e is Map) {
                    return Map<String, dynamic>.from(e);
                  }
                  return {'name': e.toString(), 'category': 'other'};
                }).toList();
              }

              // Parse skillsToLearn
              final skillsToLearnRaw = skillsData['skillsToLearn'];
              if (skillsToLearnRaw is List) {
                skillsToLearn = skillsToLearnRaw.map((e) {
                  if (e is Map) {
                    return Map<String, dynamic>.from(e);
                  }
                  return {'name': e.toString(), 'category': 'other'};
                }).toList();
              }
            }
          }
        } catch (e) {
          // Skills subcollection doesn't exist or error - use empty lists
        }

        users.add({
          ...data,
          'uid': doc.id,
          'skills': skills,
          'skillsToLearn': skillsToLearn,
        });
      }

      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    });
  }


  Future<void> _loadData() async {
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _myProfile = profile;
        });
      }
    } catch (e) {
      // Handle error
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
            itemCount: Constants.kSkillCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = Constants.kSkillCategories[index];
              final selected = cat == _selectedCategory;
              return ChoiceChip(
                label: Text('categories.${cat.toLowerCase()}'.tr()),
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
              _buildSkillsTab(),
              Center(child: Text("Coming Soon.. Stay Tuned!")),
            ],
          ),
        ),
      ],
    );
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
      // Get skills (List of Maps)
      final skills = (user['skills'] as List<Map<String, dynamic>>?) ?? [];

      // 1. Search Filter
      if (_searchQuery.isNotEmpty) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        // Check if ANY skill name contains query
        final hasSkillMatch = skills.any((s) => s['name'].toString().toLowerCase().contains(_searchQuery));
        
        if (!name.contains(_searchQuery) && !hasSkillMatch) {
          return false;
        }
      }

      // 2. Category Filter (language-agnostic)
      if (_selectedCategory != 'all') {
        // Check if ANY skill belongs to the selected category
        final hasCategoryMatch = skills.any((s) => Constants.skillMatchesCategory(s, _selectedCategory));
        if (!hasCategoryMatch) return false;
      }

      // 3. Compatibility Filter
      if (_showCompatibleOnly) {
        final compatibility = _checkCompatibility(user);
        if (compatibility['isCompatible'] == false) {
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

  Widget _buildSkillsTab() {
    final theme = Theme.of(context);
    if (_isLoadingUsers) return const Center(child: CircularProgressIndicator());

    // Build a map: Skill Name -> List of Users
    final Map<String, List<Map<String, dynamic>>> skillsToLearnMap = {};

    for (final user in _allUsers) {
      final skillsToLearn = (user['skillsToLearn'] as List<Map<String, dynamic>>?) ?? [];

      for (final skillMap in skillsToLearn) {
        // Add null safety here
        final skillName = skillMap['name']?.toString();
        final skillCategory = skillMap['category']?.toString() ?? 'Other';

        // Skip if skillName is null or empty
        if (skillName == null || skillName.isEmpty) continue;

        // Apply Category Filter here for skills tab (language-agnostic)
        if (_selectedCategory != 'all' && !Constants.skillMatchesCategory(skillMap, _selectedCategory)) {
          continue;
        }

        if (!skillsToLearnMap.containsKey(skillName)) {
          skillsToLearnMap[skillName] = [];
        }
        skillsToLearnMap[skillName]!.add(user);
      }
    }

    var filteredSkills = skillsToLearnMap.keys.toList();

    // Apply Search Filter for skills tab
    if (_searchQuery.isNotEmpty) {
      filteredSkills = filteredSkills
          .where((skill) => skill.toLowerCase().contains(_searchQuery))
          .toList();
    }

    filteredSkills.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (filteredSkills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('explore_page.no_skills_found'.tr()),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSkills.length,
      itemBuilder: (context, index) {
        final skillName = filteredSkills[index];
        final usersWantingSkill = skillsToLearnMap[skillName]!;

        // Apply compatible filter
        final displayUsers = _showCompatibleOnly
            ? usersWantingSkill.where((user) {
          final compatibility = _checkCompatibility(user);
          return compatibility['isCompatible'] == true;
        }).toList()
            : usersWantingSkill;

        if (displayUsers.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(skillName),
            subtitle: Text('explore_page.users_want_to_learn'.tr(namedArgs: {'count': displayUsers.length.toString()})),
            children: displayUsers.map((user) {
              final compatibility = _checkCompatibility(user);
              return _buildSkillUserTile(user, skillName, compatibility);
            }).toList(),
          ),
        );
      },
    );
  }



  Widget _buildUserCard(Map<String, dynamic> user, Map<String, dynamic> compatibility) {
    if (user['uid'] == null || user['name'] == null) return const SizedBox.shrink();
    
    final isCompatible = compatibility['isCompatible'] as bool;
    final theme = Theme.of(context);
    
    // EXTRACT SKILL NAMES FOR DISPLAY
    final skills = (user['skills'] as List<Map<String, dynamic>>?) ?? [];
    final skillNames = skills.map((s) => s['name'].toString()).toList();

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
              // AVATAR
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user['profilePictureBase64'] != null
                        ? MemoryImage(base64Decode(user['profilePictureBase64']))
                        : null,
                    child: user['profilePictureBase64'] == null ? const Icon(Icons.person) : null,
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
              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'explore_page.unknown'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (skillNames.isNotEmpty)
                      Text(
                        skillNames.take(3).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      user['nationality'] ?? 'explore_page.unknown_location'.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: isCompatible ? null : Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillUserTile(Map<String, dynamic> user, String skill, Map<String, dynamic> compatibility) {
    // Similar to buildUserCard but simpler for the Expandable list
    final isCompatible = compatibility['isCompatible'] as bool;
    final skills = (user['skills'] as List<Map<String, dynamic>>?) ?? [];
    final skillNames = skills.map((s) => s['name'].toString()).toList();
    
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['profilePictureBase64'] != null
            ? MemoryImage(base64Decode(user['profilePictureBase64']))
            : null,
        child: user['profilePictureBase64'] == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user['name'] ?? ''),
      subtitle: Text('explore_page.can_teach'.tr(namedArgs: {'skills': skillNames.take(2).join(', ')})),
      onTap: () => _showCompatibilityDialog(user, compatibility),
      trailing: Icon(isCompatible ? Icons.check_circle : Icons.warning, color: isCompatible ? Colors.green : Colors.red),
    );
  }

  // --- COMPATIBILITY LOGIC (Unchanged but using Map accessors correctly) ---
  Map<String, dynamic> _checkCompatibility(Map<String, dynamic> otherUser) {
    if (_myProfile == null) return {'isCompatible': true, 'reasons': []};

    final myPrefs = _myProfile?['preferences'] as Map<String, dynamic>?;
    final reasons = <String>[];

    if (myPrefs == null) return {'isCompatible': true, 'reasons': []};

    // Gender Check
    if (myPrefs['gender'] != null && myPrefs['gender'] != 'Any' && otherUser['gender'] != myPrefs['gender']) {
      reasons.add('explore_page.gender_mismatch'.tr(namedArgs: {
        'expected': myPrefs['gender'],
        'found': otherUser['gender'] ?? 'Not specified'
      }));
    }

    // Nationality Check
    if (myPrefs['nationality'] != null && myPrefs['nationality'] != 'Any' && otherUser['nationality'] != myPrefs['nationality']) {
      reasons.add('explore_page.nationality_mismatch'.tr(namedArgs: {
        'expected': myPrefs['nationality'].toString(),
        'found': otherUser['nationality']?.toString() ?? 'Not specified'
      }));
    }

    // Location Check
    if (myPrefs['locationRange'] != null && _myProfile?['location'] != null && otherUser['location'] != null) {
      try {
        final distance = _calculateDistance(_myProfile!['location'], otherUser['location']);
        if (distance > (myPrefs['locationRange'] as num)) {
          reasons.add('explore_page.too_far'.tr(namedArgs: {
            'distance': distance.toStringAsFixed(0),
            'limit': myPrefs['locationRange'].toString()
          }));
        }
      } catch (e) { /* ignore */ }
    }

    // Age Check
    if (myPrefs['ageRange'] != null && otherUser['dateOfBirth'] != null) {
      try {
        final age = _calculateAge(otherUser['dateOfBirth']);
        final ageRangeMap = myPrefs['ageRange'] as Map<String, dynamic>;
        final min = (ageRangeMap['min'] as num?)?.toInt() ?? 18;
        final max = (ageRangeMap['max'] as num?)?.toInt() ?? 100;
        if (age < min || age > max) {
          reasons.add('explore_page.age_outside_range'.tr(namedArgs: {'age': age.toString(), 'min': min.toString(), 'max': max.toString()}));
        }
      } catch (e) { /* ignore */ }
    }

    // Religion Check
    if (myPrefs['religion'] != null && myPrefs['religion'] != 'Any' && otherUser['religion'] != null && otherUser['religion'] != myPrefs['religion']) {
      reasons.add('explore_page.religion_preference'.tr(namedArgs: {'expected': myPrefs['religion'], 'found': otherUser['religion']}));
    }

    return {'isCompatible': reasons.isEmpty, 'reasons': reasons};
  }

  // --- MATH HELPERS (Unchanged) ---
  int _calculateAge(dynamic dateOfBirth) {
    DateTime dob;
    if (dateOfBirth is Timestamp) {
      dob = dateOfBirth.toDate();
    } else if (dateOfBirth is String) {
      dob = DateTime.parse(dateOfBirth);
    } else {
      return 25; // Default fallback
    }
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  double _calculateDistance(dynamic loc1, dynamic loc2) {
    const R = 6371; // Earth radius in km
    double lat1, lon1, lat2, lon2;
    try {
      if (loc1 is GeoPoint) { lat1 = loc1.latitude; lon1 = loc1.longitude; }
      else { lat1 = (loc1['latitude'] as num).toDouble(); lon1 = (loc1['longitude'] as num).toDouble(); }

      if (loc2 is GeoPoint) { lat2 = loc2.latitude; lon2 = loc2.longitude; }
      else { lat2 = (loc2['latitude'] as num).toDouble(); lon2 = (loc2['longitude'] as num).toDouble(); }

      final dLat = _toRadians(lat2 - lat1);
      final dLon = _toRadians(lon2 - lon1);
      final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return R * c;
    } catch (e) { return double.infinity; }
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  void _showCompatibilityDialog(Map<String, dynamic> user, Map<String, dynamic> compatibility) async {
    // ... Copy your existing dialog logic here, ensure you use 'user['uid']' ...
    // Since the dialog logic is long and mostly UI, I kept it standard.
    // Just ensure you call ConnectionService().getConnectionStatus(user['uid']);
     final isCompatible = compatibility['isCompatible'] as bool;
    final reasons = (compatibility['reasons'] as List<dynamic>).map((e) => e.toString()).toList();
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
              // Use skill NAMES here
              Text('${user['nationality']} • ${(user['skills'] as List<Map<String,dynamic>>?)?.map((e) => e['name']).join(', ') ?? 'explore_page.no_skills'.tr()}'),
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
          ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple, 
            foregroundColor: Colors.white,                          
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            
          ),
          child: Text('explore_page.close'.tr()),
        ),

  const SizedBox(width: 10),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('explore_page.connect'.tr()),
            )
          else if (status == 'pending')
            ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(                       
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            
            ),
              child: Text('explore_page.pending'.tr()),
            )
          else if (status == 'accepted')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(                       
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.black54,
                ),
                child: Text('Message'),
              ),
        ],
      ),
    );
  }
}