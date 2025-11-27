import 'package:flutter/foundation.dart';
import '../data/models/interest.dart';
import '../data/models/category_progress.dart';

/// Central store for computing progress locally from catalog + ratings
/// Progress is computed in memory, not fetched from Supabase
class ProgressStore extends ChangeNotifier {
  // Progress by category code (list code)
  Map<String, CategoryProgress> _categoryProgress = {};
  
  // Progress by group (sectionCode + groupCode)
  Map<String, CategoryProgress> _groupProgress = {};
  
  // Progress by section (sectionCode)
  Map<String, CategoryProgress> _sectionProgress = {};

  // Getters
  Map<String, CategoryProgress> get categoryProgress => Map.unmodifiable(_categoryProgress);
  Map<String, CategoryProgress> get groupProgress => Map.unmodifiable(_groupProgress);
  Map<String, CategoryProgress> get sectionProgress => Map.unmodifiable(_sectionProgress);

  /// Recompute all progress from catalog items and ratings
  void recompute({
    required List<Interest> items,
    required Map<int, int> ratings, // item_id -> value
  }) {
    _categoryProgress.clear();
    _groupProgress.clear();
    _sectionProgress.clear();

    // Helper: Get progress for a set of items
    CategoryProgress _computeProgressForItems(List<Interest> items, String categoryName) {
      // Remove duplicates (item can be in multiple lists)
      final uniqueItems = <int, Interest>{};
      for (var item in items) {
        uniqueItems[item.id] = item;
      }
      final uniqueList = uniqueItems.values.toList();
      final total = uniqueList.length;
      final rated = uniqueList.where((item) => ratings.containsKey(item.id)).length;
      return CategoryProgress(
        category: categoryName,
        ratedCount: rated,
        totalCount: total,
      );
    }

    // Group items by list code (category)
    final itemsByListCode = <String, List<Interest>>{};
    for (var item in items) {
      for (var listCode in item.listCodes) {
        itemsByListCode.putIfAbsent(listCode, () => []).add(item);
      }
    }

    // Compute category progress
    for (var entry in itemsByListCode.entries) {
      final listCode = entry.key;
      final categoryItems = entry.value;
      _categoryProgress[listCode] = _computeProgressForItems(
        categoryItems,
        listCode,
      );
    }

    notifyListeners();
  }

  /// Get progress for a category (list code)
  CategoryProgress? getCategoryProgress(String listCode) {
    return _categoryProgress[listCode];
  }

  /// Get progress for a group (sectionCode + groupCode)
  /// This aggregates all categories in the group
  CategoryProgress? getGroupProgress(String sectionCode, String groupCode, {
    required List<Interest> allItems,
    required Map<int, int> ratings,
    required List<String> groupListCodes, // list codes in this group
  }) {
    final key = '$sectionCode:$groupCode';
    
    // Always recompute (ratings may have changed)
    // Compute progress for all items in this group
    final groupItems = allItems.where((item) {
      return item.listCodes.any((code) => groupListCodes.contains(code));
    }).toList();

    // Remove duplicates
    final uniqueItems = <int, Interest>{};
    for (var item in groupItems) {
      uniqueItems[item.id] = item;
    }

    final progress = CategoryProgress(
      category: groupCode,
      ratedCount: uniqueItems.values.where((item) => ratings.containsKey(item.id)).length,
      totalCount: uniqueItems.length,
    );

    _groupProgress[key] = progress;
    return progress;
  }

  /// Get progress for a section (sectionCode)
  /// This aggregates all groups in the section
  CategoryProgress? getSectionProgress(String sectionCode, {
    required List<Interest> allItems,
    required Map<int, int> ratings,
    required List<String> sectionListCodes, // all list codes in this section
  }) {
    // Always recompute (ratings may have changed)
    // Compute progress for all items in this section
    final sectionItems = allItems.where((item) {
      return item.listCodes.any((code) => sectionListCodes.contains(code));
    }).toList();

    // Remove duplicates
    final uniqueItems = <int, Interest>{};
    for (var item in sectionItems) {
      uniqueItems[item.id] = item;
    }

    final progress = CategoryProgress(
      category: sectionCode,
      ratedCount: uniqueItems.values.where((item) => ratings.containsKey(item.id)).length,
      totalCount: uniqueItems.length,
    );

    _sectionProgress[sectionCode] = progress;
    return progress;
  }

  /// Clear all progress (useful for logout or full reload)
  void clear() {
    _categoryProgress.clear();
    _groupProgress.clear();
    _sectionProgress.clear();
    notifyListeners();
  }
}

