import 'package:flutter/material.dart';
import 'package:skillswap/services/profile_service.dart';
import 'profile_setup_page.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _checkProfileSetup();
  }

  Future<void> _checkProfileSetup() async {
    final isCompleted = await _profileService.isProfileSetupCompleted();

    if (!mounted) return;

    if (!isCompleted) {
      _navigateToProfileSetup();
    } else {
      await _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _profileService.getProfile();
      if (mounted) {
        if (data == null ||
            data['profileSetupCompleted'] != true ||
            data['name'] == null) {
          _showSetupDialog();
          return;
        }

        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: const Text(
            'Finish setting up your profile to start connecting with others!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToProfileSetup();
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfileSetup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
    );

    if (result == true && mounted) {
      setState(() {
        _isLoading = true;
      });
      await _loadProfile();
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfilePicture(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const CircleAvatar(
        radius: 60,
        child: Icon(Icons.person, size: 60),
      );
    }

    try {
      final bytes = base64Decode(base64String);
      return CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
      );
    } catch (e) {
      return const CircleAvatar(
        radius: 60,
        child: Icon(Icons.person, size: 60),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profileData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Unable to load profile'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfilePicture(_profileData!['profilePictureBase64']),
          const SizedBox(height: 16),
          Text(
            _profileData!['name'] ?? 'No Name',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _profileData!['email'] ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildSkillsCard(),
          const SizedBox(height: 16),
          _buildPreferencesCard(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToProfileSetup,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(Icons.person, 'Gender', _profileData!['gender']),
            _buildInfoRow(Icons.flag, 'Nationality', _profileData!['nationality']),
            _buildInfoRow(Icons.phone, 'Phone', _profileData!['phoneNumber']),
            if (_profileData!['location'] != null)
              _buildInfoRow(Icons.location_on, 'Location', 'Enabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    final skills = (_profileData!['skills'] as List?)?.cast<String>() ?? [];

    if (skills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skills',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((skill) => Chip(
                label: Text(skill),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    final preferences = _profileData!['preferences'] as Map<String, dynamic>?;

    if (preferences == null || preferences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partner Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (preferences['gender'] != null)
              _buildInfoRow(Icons.wc, 'Gender', preferences['gender']),
            if (preferences['nationality'] != null)
              _buildInfoRow(Icons.flag, 'Nationality', preferences['nationality']),
            if (preferences['religion'] != null)
              _buildInfoRow(Icons.church, 'Religion', preferences['religion']),
            if (preferences['ageRange'] != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Age Range',
                '${preferences['ageRange']['min']?.round()} - ${preferences['ageRange']['max']?.round()} years',
              ),
            if (preferences['locationRange'] != null)
              _buildInfoRow(
                Icons.location_searching,
                'Distance',
                '${preferences['locationRange']?.round()} km',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
