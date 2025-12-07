import 'package:flutter/material.dart';
import 'package:skillswap/services/profile_service.dart';
import 'profile_setup_page.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';

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
          SnackBar(content: Text('profile_page.error_loading'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    }
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('complete_profile'.tr()),
        content: Text('finish_profile_message'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToProfileSetup();
            },
            child: Text('get_started'.tr()),
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

  Widget _buildProfilePicture(BuildContext context, String? base64String) {
    final theme = Theme.of(context);
    if (base64String == null || base64String.isEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.surface,
        child: Icon(Icons.person, size: 60, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      );
    }

    try {
      final bytes = base64Decode(base64String);
      return CircleAvatar(
        radius: 60,
        backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
      );
    } catch (e) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.surface,
        child: Icon(Icons.person, size: 60, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profileData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('profile_page.unable_to_load'.tr()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: Text('profile_page.retry'.tr()),
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
          _buildProfilePicture(context, _profileData!['profilePictureBase64']),
          const SizedBox(height: 16),
          Text(
            _profileData!['name'] ?? 'profile_page.no_name'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _profileData!['email'] ?? '',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildSkillsCard(context),
          const SizedBox(height: 16),
          _buildPreferencesCard(context),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToProfileSetup,
            icon: const Icon(Icons.edit),
            label: Text('edit_profile'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile_page.personal_information'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow(context, Icons.person, 'gender'.tr(), _profileData!['gender']),
            _buildInfoRow(context, Icons.flag, 'nationality'.tr(), _profileData!['nationality']),
            _buildInfoRow(context, Icons.phone, 'profile_page.phone'.tr(), _profileData!['phoneNumber']),
            _buildInfoRow(context, Icons.description, 'profile_page.description'.tr(), _profileData!['description']),
            if (_profileData!['location'] != null)
              _buildInfoRow(context, Icons.location_on, 'location'.tr(), 'profile_page.enabled'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard(BuildContext context) {
    final theme = Theme.of(context);
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
            Text(
              'skills'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((skill) => Chip(
                label: Text(skill),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context) {
    final theme = Theme.of(context);
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
            Text(
              'profile_page.partner_preferences'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (preferences['gender'] != null)
              _buildInfoRow(context, Icons.wc, 'gender'.tr(), preferences['gender']),
            if (preferences['nationality'] != null)
              _buildInfoRow(context, Icons.flag, 'nationality'.tr(), preferences['nationality']),
            if (preferences['religion'] != null)
              _buildInfoRow(context, Icons.church, 'profile_page.religion'.tr(), preferences['religion']),
            if (preferences['ageRange'] != null)
              _buildInfoRow(
                context,
                Icons.calendar_today,
                'ageRange'.tr(),
                'profile_page.age_range'.tr(namedArgs: {
                  'min': preferences['ageRange']['min']?.round().toString() ?? '0',
                  'max': preferences['ageRange']['max']?.round().toString() ?? '0'
                }),
              ),
            if (preferences['locationRange'] != null)
              _buildInfoRow(
                context,
                Icons.location_searching,
                'locationRange'.tr(),
                'profile_page.distance'.tr(namedArgs: {
                  'distance': preferences['locationRange']?.round().toString() ?? '0'
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, dynamic value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
