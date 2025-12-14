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

    Widget avatarContent;
    if (base64String == null || base64String.isEmpty) {
      avatarContent = CircleAvatar(
        radius: 55,
        backgroundColor: theme.colorScheme.surface,
        child: Icon(Icons.person, size: 55, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      );
    } else {
      try {
        final bytes = base64Decode(base64String);
        avatarContent = CircleAvatar(
          radius: 55,
          backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
        );
      } catch (e) {
        avatarContent = CircleAvatar(
          radius: 55,
          backgroundColor: theme.colorScheme.surface,
          child: Icon(Icons.person, size: 55, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.6),
            theme.colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: avatarContent,
      ),
    );
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text('profile_page.unable_to_load'.tr(), style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: Text('profile_page.retry'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Gradient Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.85),
                  theme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: [
                    _buildProfilePicture(context, _profileData!['profilePictureBase64']),
                    const SizedBox(height: 20),
                    Text(
                      _profileData!['name'] ?? 'profile_page.no_name'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 8),
                          Text(
                            _profileData!['email'] ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Edit Profile Button
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      child: InkWell(
                        onTap: _navigateToProfileSetup,
                        borderRadius: BorderRadius.circular(25),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 20, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'edit_profile'.tr(),
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildInfoCard(context),
                const SizedBox(height: 16),
                _buildSkillsCard(context),
                const SizedBox(height: 16),
                _buildPreferencesCard(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_outline, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'profile_page.personal_information'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'skills'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: skills
                  .map((skill) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withValues(alpha: 0.15),
                              theme.primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.purple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'profile_page.partner_preferences'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString() ?? 'N/A',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
