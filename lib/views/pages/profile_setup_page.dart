import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skillswap/services/profile_service.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:skillswap/data/constants.dart';
import 'package:dropdown_search/dropdown_search.dart';


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
            _phoneController.text = phoneNumber.substring(_selectedCountryCode.length);
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
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }


  Future<bool> _requestCameraPermission() async {
    final cameraPermission = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text('Do you allow SkillSwap to access your camera?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (cameraPermission != true) return false;

    final status = await Permission.camera.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to take photos'),
            action: SnackBarAction(
              label: 'Settings',
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
        title: const Text('Location Permission'),
        content: const Text(
            'Do you allow SkillSwap to use your location while using the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (result != true) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Getting your location...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them in settings.'),
              duration: Duration(seconds: 3),
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
              const SnackBar(
                content: Text('Location permission denied'),
                duration: Duration(seconds: 2),
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
            const SnackBar(
              content: Text('Location permission permanently denied. Please enable in settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: Geolocator.openLocationSettings,
              ),
              duration: Duration(seconds: 5),
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
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Text('Location enabled successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
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
          const SnackBar(content: Text('Please select your date of birth')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
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
              title: const Text('Basic Information'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProfilePicturePreview(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_profilePicturePath == null
                        ? 'Add Profile Picture'
                        : 'Change Picture'),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
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
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateOfBirth == null
                            ? 'Select Date of Birth'
                            : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                    validator: (v) => v == null ? 'Gender is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownSearch<String>(
                    items: (filter, infiniteScrollProps) async => Constants.nationalities,
                    selectedItem: _nationality,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Nationality',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search nationality...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(() => _nationality = v),
                    validator: (v) => v == null ? 'Nationality is required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: DropdownSearch<Map<String, String>>(
                          items: (filter, infiniteScrollProps) async => Constants.phoneCountryCodes,
                          selectedItem: Constants.phoneCountryCodes.firstWhere(
                                (c) => c['code'] == _selectedCountryCode,
                            orElse: () => Constants.phoneCountryCodes.first,
                          ),
                          itemAsString: (country) => '${country['name']} ${country['code']}',
                          compareFn: (item1, item2) => item1['code'] == item2['code'],
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: 'Code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search country...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          onChanged: (country) {
                            if (country != null) {
                              setState(() => _selectedCountryCode = country['code']!);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                          v?.isEmpty ?? true ? 'Phone number is required' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Location'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Location helps us find skill swap partners near you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _requestLocation,
                    icon: const Icon(Icons.location_on),
                    label: Text(_location == null
                        ? 'Enable Location'
                        : 'Location Enabled ✓'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _location != null ? Colors.green : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Step(
              title: const Text('Preferences'),
              isActive: _currentStep >= 2,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Your Short Description',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillController,
                          decoration: const InputDecoration(
                            hintText: 'Let your partner know something about you',
                            border: OutlineInputBorder(),
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
                                ? 'No description added'
                                : _description!,
                            style: TextStyle(
                              color: _description == null || _description!.isEmpty
                                  ? Colors.grey
                                  : Colors.purple,
                            ),
                          ),
                        ),
                        if (_description != null && _description!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() => _description = null),
                            iconSize: 20,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Partner Preferences',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _preferredGender,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Male', 'Female', 'Any']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _preferredGender = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Preferred Nationality (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _preferredNationality = v,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Preferred Religion (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _preferredReligion = v,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()} years',
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
                    'Location Range: ${_locationRange.round()} km',
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
