import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skillswap/services/profile_service.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:skillswap/data/constants.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:easy_localization/easy_localization.dart';

//TODO: Solve Add Profile Picture visual bug

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  String _selectedCountryCode = '+1';

  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  String? _nationality;
  String? _profilePicturePath;
  String? _location;
  String? _description;
  final _skillController = TextEditingController();

  // Preferences
  String? _preferredGender;
  String? _preferredNationality;
  String? _preferredReligion;
  RangeValues _ageRange = const RangeValues(18, 65);
  double _locationRange = 50;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await _profileService.getProfile();

      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _dateOfBirth = profile['dateOfBirth']?.toDate();
          _gender = profile['gender'];
          _nationality = profile['nationality'];

          // Parse phone number
          final phoneNumber = profile['phoneNumber'] as String?;
          if (phoneNumber != null) {
            final code = Constants.phoneCountryCodes.firstWhere(
              (c) => phoneNumber.startsWith(c['code']!),
              orElse: () => {'code': '+1'},
            );
            _selectedCountryCode = code['code']!;
            _phoneController.text = phoneNumber.substring(
              _selectedCountryCode.length,
            );
          }

          _profilePicturePath = profile['profilePicturePath'] as String?;

          final locationData = profile['location'];
          if (locationData != null) {
            if (locationData is String) {
              _location = locationData;
            } else {
              _location = '${locationData.latitude},${locationData.longitude}';
            }
          }
          final description = profile['description'] as String?;
          if (description != null) {
            _description = description;
          }

          final prefs = profile['preferences'] as Map<String, dynamic>?;
          if (prefs != null) {
            _preferredGender = prefs['gender'];
            _preferredNationality = prefs['nationality'];
            _preferredReligion = prefs['religion'];

            final ageRange = prefs['ageRange'] as Map<String, dynamic>?;
            if (ageRange != null) {
              _ageRange = RangeValues(
                (ageRange['min'] as num).toDouble(),
                (ageRange['max'] as num).toDouble(),
              );
            }

            _locationRange = (prefs['locationRange'] as num?)?.toDouble() ?? 50;
          }
        });
      }
    } catch (e) {
      print('Error loading existing profile: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile_setup_page.choose_image_source'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('profile_setup_page.gallery'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('profile_setup_page.camera'.tr()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (result == ImageSource.camera) {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) return;
    }

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: result,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profilePicturePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('profile_setup_page.error_picking_image'.tr(namedArgs: {'error': e.toString()})),
        ));
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    final cameraPermission = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile_setup_page.camera_permission_title'.tr()),
        content: Text('profile_setup_page.camera_permission_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('profile_setup_page.deny'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('profile_setup_page.allow'.tr()),
          ),
        ],
      ),
    );

    if (cameraPermission != true) return false;

    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_setup_page.camera_permission_required'.tr()),
            action: SnackBarAction(
              label: 'profile_setup_page.settings'.tr(),
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return false;
    }

    return status.isGranted;
  }

  Future<void> _requestLocation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile_setup_page.location_permission_title'.tr()),
        content: Text(
          'profile_setup_page.location_permission_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('profile_setup_page.deny'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('profile_setup_page.allow'.tr()),
          ),
        ],
      ),
    );

    if (result != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Text('profile_setup_page.getting_location'.tr()),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_setup_page.location_services_disabled'.tr(),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile_setup_page.location_permission_denied'.tr()),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_setup_page.location_permission_permanently_denied'.tr(),
              ),
              action: SnackBarAction(
                label: 'profile_setup_page.settings'.tr(),
                onPressed: Geolocator.openLocationSettings,
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _location = '${position.latitude},${position.longitude}';
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Text('profile_setup_page.location_enabled_success'.tr()),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_setup_page.error_getting_location'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _saveDescription() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _description = _skillController.text;
        _skillController.clear();
      });
    }
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_setup_page.select_dob_error'.tr())),
        );
        return;
      }

      try {
        final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text}';
        await _profileService.saveProfile(
          name: _nameController.text,
          dateOfBirth: _dateOfBirth!,
          gender: _gender!,
          nationality: _nationality!,
          phoneNumber: fullPhoneNumber,
          profilePicturePath: _profilePicturePath,
          location: _location,
          description: _description,
          preferences: {
            'gender': _preferredGender,
            'nationality': _preferredNationality,
            'religion': _preferredReligion,
            'ageRange': {'min': _ageRange.start, 'max': _ageRange.end},
            'locationRange': _locationRange,
          },
        );

        await _profileService.markProfileSetupCompleted();

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('profile_setup_page.error_saving_profile'.tr(namedArgs: {'error': e.toString()}))));
        }
      }
    }
  }

  Widget _buildProfilePicturePreview() {
    if (_profilePicturePath == null) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 50, color: Colors.grey),
      );
    }

    return ClipOval(
      child: Image.file(
        File(_profilePicturePath!),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('profile_setup_page.title'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text('profile_setup_page.button_back'.tr()),
                    ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 2 ? 'profile_setup_page.button_submit'.tr() : 'profile_setup_page.button_continue'.tr()),
                  ),
                ],
              ),
            );
          },
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submitProfile();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            Step(
              title: Text('profile_setup_page.step_basic_info'.tr()),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProfilePicturePreview(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 180,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _profilePicturePath == null
                            ? 'profile_setup_page.add_profile_picture'.tr()
                            : 'profile_setup_page.change_picture'.tr(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'profile_setup_page.full_name'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'profile_setup_page.name_required'.tr() : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _dateOfBirth = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'profile_setup_page.date_of_birth'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateOfBirth == null
                            ? 'profile_setup_page.select_date_of_birth'.tr()
                            : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(
                      labelText: 'profile_setup_page.gender'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.wc),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Male', child: Text('profile_setup_page.male'.tr())),
                      DropdownMenuItem(value: 'Female', child: Text('profile_setup_page.female'.tr())),
                      DropdownMenuItem(value: 'Other', child: Text('profile_setup_page.other'.tr())),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (v) => v == null ? 'profile_setup_page.gender_required'.tr() : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) async =>
                        Constants.nationalities,
                    selectedItem: _nationality,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'profile_setup_page.nationality'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'profile_setup_page.search_nationality'.tr(),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _nationality = v),
                    validator: (v) =>
                        v == null ? 'profile_setup_page.nationality_required'.tr() : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: DropdownSearch<Map<String, String>>(
                          items: (filter, infiniteScrollProps) async =>
                              Constants.phoneCountryCodes,
                          selectedItem: Constants.phoneCountryCodes.firstWhere(
                            (c) => c['code'] == _selectedCountryCode,
                            orElse: () => Constants.phoneCountryCodes.first,
                          ),
                          itemAsString: (country) =>
                              '${country['name']} ${country['code']}',
                          compareFn: (item1, item2) =>
                              item1['code'] == item2['code'],
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: 'profile_setup_page.phone_code'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'profile_setup_page.search_country'.tr(),
                                prefixIcon: const Icon(Icons.search),
                              ),
                            ),
                          ),
                          onChanged: (country) {
                            if (country != null) {
                              setState(
                                () => _selectedCountryCode = country['code']!,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'profile_setup_page.phone_number'.tr(),
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v?.isEmpty ?? true
                              ? 'profile_setup_page.phone_required'.tr()
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Step(
              title: Text('profile_setup_page.step_location'.tr()),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'profile_setup_page.location_help_text'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _requestLocation,
                    icon: const Icon(Icons.location_on),
                    label: Text(
                      _location == null
                          ? 'profile_setup_page.enable_location'.tr()
                          : 'profile_setup_page.location_enabled'.tr(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _location != null ? Colors.green : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Step(
              title: Text('profile_setup_page.step_preferences'.tr()),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'profile_setup_page.short_description_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillController,
                          decoration: InputDecoration(
                            hintText:
                                'profile_setup_page.short_description_hint'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _saveDescription,
                        icon: const Icon(Icons.add_circle),
                        iconSize: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _description == null || _description!.isEmpty
                                ? 'profile_setup_page.no_description'.tr()
                                : _description!,
                            style: TextStyle(
                              color:
                                  _description == null || _description!.isEmpty
                                  ? Colors.grey
                                  : Colors.purple,
                            ),
                          ),
                        ),
                        if (_description != null && _description!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                setState(() => _description = null),
                            iconSize: 20,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'profile_setup_page.partner_preferences_title'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _preferredGender,
                    decoration: InputDecoration(
                      labelText: 'profile_setup_page.preferred_gender'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Male', child: Text('profile_setup_page.male'.tr())),
                      DropdownMenuItem(value: 'Female', child: Text('profile_setup_page.female'.tr())),
                      DropdownMenuItem(value: 'Any', child: Text('profile_setup_page.any'.tr())),
                    ],
                    onChanged: (v) => setState(() => _preferredGender = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) async =>
                    Constants.nationalities,
                    selectedItem: _preferredNationality,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'profile_setup_page.preferred_nationality'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'profile_setup_page.search_nationality'.tr(),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _preferredNationality = v),
                    validator: (v) =>
                    v == null ? 'profile_setup_page.preferred_nationality_required'.tr() : null,
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'profile_setup_page.preferred_religion'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => _preferredReligion = v,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'profile_setup_page.age_range'.tr(namedArgs: {
                      'min': _ageRange.start.round().toString(),
                      'max': _ageRange.end.round().toString(),
                    }),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 100,
                    divisions: 82,
                    labels: RangeLabels(
                      _ageRange.start.round().toString(),
                      _ageRange.end.round().toString(),
                    ),
                    onChanged: (v) => setState(() => _ageRange = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'profile_setup_page.location_range'.tr(namedArgs: {
                      'distance': _locationRange.round().toString(),
                    }),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: _locationRange,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    label: '${_locationRange.round()} km',
                    onChanged: (v) => setState(() => _locationRange = v),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
