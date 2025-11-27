import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../stores/catalog_store.dart';
import '../../data/models/interest_list.dart';
import '../../widgets/category_item.dart';
import 'onboarding_done_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String sectionCode; // e.g., 'Entertainment'
  final String groupCode; // e.g., 'MOVIES', 'YOUTUBE', 'SPORTS'

  const CategoriesScreen({
    Key? key,
    required this.sectionCode,
    required this.groupCode,
  }) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final Set<String> _selectedListCodes = {};
  final List<String> _selectedListCodesOrdered = []; // Maintain selection order
  bool _isLoading = true;
  List<InterestList> _lists = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    try {
      // Use CatalogStore to get lists by section and group
      // This ensures we only get lists with the exact section_code and group_code match
      final catalogStore = Provider.of<CatalogStore>(context, listen: false);
      
      if (!catalogStore.isLoaded) {
        // Wait for catalog to load
        await Future.delayed(const Duration(milliseconds: 100));
        if (!catalogStore.isLoaded) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Catalog not loaded yet. Please try again.')),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }
      }
      
      final lists = catalogStore.getListsBySectionAndGroup(
        widget.sectionCode,
        widget.groupCode,
      );
      
      setState(() {
        _lists = lists;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lists: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleList(String listCode) {
    setState(() {
      if (_selectedListCodes.contains(listCode)) {
        _selectedListCodes.remove(listCode);
        _selectedListCodesOrdered.remove(listCode);
      } else {
        _selectedListCodes.add(listCode);
        _selectedListCodesOrdered.add(listCode); // Add in selection order
      }
    });
  }

  void _handleNext() {
    if (_selectedListCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
        ),
      );
      return;
    }

    // After selecting lists, go to onboarding done screen
    // User can rate interests later if they want
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const OnboardingDoneScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Categories'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choose your interest categories',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select all categories you\'re interested in',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _lists.map((list) {
                                return CategoryItem(
                                  category: list.title,
                                  isSelected: _selectedListCodes.contains(list.code),
                                  onTap: () => _toggleList(list.code),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

