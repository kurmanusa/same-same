import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/interests_repository.dart';
import '../../data/models/interest.dart' as models;
import '../../data/models/interest_list.dart';
import '../../widgets/interest_item.dart';
import 'categories_screen.dart';
import 'progress_screen.dart';

class CategoryInterestsScreen extends StatefulWidget {
  final List<InterestList> lists;
  final int currentListIndex;

  const CategoryInterestsScreen({
    Key? key,
    required this.lists,
    this.currentListIndex = 0,
  }) : super(key: key);

  @override
  State<CategoryInterestsScreen> createState() => _CategoryInterestsScreenState();
}

class _CategoryInterestsScreenState extends State<CategoryInterestsScreen> {
  final _interestsRepository = InterestsRepository();
  bool _isLoading = true;
  List<models.Interest> _interests = [];
  final Map<int, int> _userRatings = {}; // interestId -> value (-1 or 1)

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadInterests();
    _loadUserRatings();
  }

  Future<void> _loadInterests() async {
    if (widget.currentListIndex >= widget.lists.length) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final list = widget.lists[widget.currentListIndex];
      final items = await _interestsRepository.getItemsByListCode(list.code);
      
      if (mounted) {
        setState(() {
          _interests = items;
          _isLoading = false;
        });
        
        // Show message if no interests found
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No interests found for list "${list.title}". Please check if interests are added to the database.'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading interests: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _isLoading = false;
          _interests = [];
        });
      }
    }
  }

  Future<void> _loadUserRatings() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final ratings = await _interestsRepository.getUserInterests(userId);
      setState(() {
        _userRatings.addAll(ratings);
      });
    } catch (e) {
      // Silently fail - user may not have rated anything yet
    }
  }

  Future<void> _handleRating(int itemId, int? value) async {
    final userId = _currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to rate interests')),
      );
      return;
    }

    try {
      await _interestsRepository.setUserInterest(
        userId: userId,
        itemId: itemId,
        value: value,
      );
      setState(() {
        if (value == null) {
          _userRatings.remove(itemId);
        } else {
          _userRatings[itemId] = value;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving rating: $e')),
        );
      }
    }
  }

  void _handleNext() {
    if (widget.currentListIndex < widget.lists.length - 1) {
      // Move to next list - use push to preserve navigation history
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CategoryInterestsScreen(
            lists: widget.lists,
            currentListIndex: widget.currentListIndex + 1,
          ),
        ),
      );
    } else {
      // All lists done, go to progress screen
      // Clear navigation stack up to welcome screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const ProgressScreen(),
        ),
        (route) {
          // Keep only the root route (WelcomeScreen)
          return route.isFirst;
        },
      );
    }
  }

  String get _currentListTitle {
    if (widget.currentListIndex >= widget.lists.length) {
      return '';
    }
    return widget.lists[widget.currentListIndex].title;
  }

  bool get _isLastList {
    return widget.currentListIndex >= widget.lists.length - 1;
  }

  void _handleBack() {
    // Get sectionCode and groupCode from the first list
    final firstList = widget.lists.isNotEmpty ? widget.lists[0] : null;
    final sectionCode = firstList?.sectionCode ?? 'Entertainment';
    final groupCode = firstList?.groupCode ?? 'MOVIES';
    
    // If this is the first list (index 0), always go back to CategoriesScreen
    if (widget.currentListIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CategoriesScreen(
            sectionCode: sectionCode,
            groupCode: groupCode,
          ),
        ),
      );
    } else if (Navigator.canPop(context)) {
      // For subsequent lists, just pop
      Navigator.pop(context);
    } else {
      // Fallback: navigate to CategoriesScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CategoriesScreen(
            sectionCode: sectionCode,
            groupCode: groupCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentListTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'List ${widget.currentListIndex + 1} of ${widget.lists.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  LinearProgressIndicator(
                    value: (widget.currentListIndex + 1) / widget.lists.length,
                    backgroundColor: Colors.grey[200],
                  ),
                ],
              ),
            ),
            // Interests list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _interests.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No interests found in this category',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'List: ${_currentListTitle}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _loadInterests,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _interests.length,
                          itemBuilder: (context, index) {
                            final item = _interests[index];
                            return InterestItem(
                              label: item.label,
                              year: item.year,
                              thumbnailPath: item.thumbnailPath,
                              currentValue: _userRatings[item.id],
                              onLike: (value) => _handleRating(item.id, value),
                              onDislike: (value) => _handleRating(item.id, value),
                            );
                          },
                        ),
            ),
            // Next button
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
                child: Text(
                  _isLastList ? 'Finish' : 'Next List',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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

