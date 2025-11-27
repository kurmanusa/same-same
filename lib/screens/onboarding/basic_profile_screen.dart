import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';
import 'categories_screen.dart';

class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({Key? key}) : super(key: key);

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationCountryController = TextEditingController();
  final _locationCityController = TextEditingController();
  final _languagesController = TextEditingController();
  
  String? _selectedGender;
  bool _isLoading = false;
  
  final _profileRepository = ProfileRepository();
  
  final List<String> _genderOptions = [
    'male',
    'female',
    'other',
    'prefer not to say',
  ];

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _locationCountryController.dispose();
    _locationCityController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = _currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to continue')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final languages = _languagesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _profileRepository.updateBasicProfile(
        userId: userId,
        displayName: _displayNameController.text.trim(),
        age: _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
        gender: _selectedGender,
        locationCountry: _locationCountryController.text.trim().isEmpty
            ? null
            : _locationCountryController.text.trim(),
        locationCity: _locationCityController.text.trim().isEmpty
            ? null
            : _locationCityController.text.trim(),
        languages: languages.isEmpty ? null : languages,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoriesScreen(
              sectionCode: 'Entertainment', // Default section for onboarding
              groupCode: 'MOVIES', // Default group for onboarding
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your display name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Age
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 13 || age > 120) {
                      return 'Please enter a valid age (13-120)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender[0].toUpperCase() + gender.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Location Country
              TextFormField(
                controller: _locationCountryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  hintText: 'Enter your country',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Location City
              TextFormField(
                controller: _locationCityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter your city',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Languages
              TextFormField(
                controller: _languagesController,
                decoration: const InputDecoration(
                  labelText: 'Languages (comma-separated)',
                  hintText: 'e.g., English, Spanish, French',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              // Next button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

