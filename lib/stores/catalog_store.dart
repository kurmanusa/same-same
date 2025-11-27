import 'package:flutter/foundation.dart';
import '../data/models/interest_section.dart';
import '../data/models/interest_list.dart';
import '../data/models/interest.dart';
import '../data/models/group_info.dart';

/// Central store for all interest catalog data (sections, lists, items)
/// Loaded once at app startup and kept in memory
class CatalogStore extends ChangeNotifier {
  List<InterestSection> _sections = [];
  List<InterestList> _lists = [];
  List<Interest> _items = [];
  
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  // Getters
  List<InterestSection> get sections => _sections;
  List<InterestList> get lists => _lists;
  List<Interest> get items => _items;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  /// Get sections by code
  InterestSection? getSectionByCode(String code) {
    try {
      return _sections.firstWhere((s) => s.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get lists by section code
  /// IMPORTANT: Filters by explicit section_code match - no inference
  List<InterestList> getListsBySection(String sectionCode) {
    final result = _lists.where((list) => list.sectionCode == sectionCode).toList();
    // Sort by group_title, then title for consistent display
    result.sort((a, b) {
      final groupCompare = a.groupTitle.compareTo(b.groupTitle);
      if (groupCompare != 0) return groupCompare;
      return a.title.compareTo(b.title);
    });
    return result;
  }

  /// Get distinct groups for a section with their titles
  /// IMPORTANT: Only returns groups from lists where sectionCode matches exactly
  /// No inference, no fallback - uses explicit section_code from loaded data
  /// Returns GroupInfo objects with groupCode (for queries) and groupTitle (for display)
  List<GroupInfo> getGroupsBySection(String sectionCode) {
    // Filter lists by section_code first (explicit match)
    final sectionLists = _lists.where((list) => list.sectionCode == sectionCode).toList();
    
    // Extract distinct (groupCode, groupTitle) pairs
    final groupMap = <String, GroupInfo>{}; // groupCode -> GroupInfo
    for (var list in sectionLists) {
      if (list.groupCode.isNotEmpty) {
        groupMap[list.groupCode] = GroupInfo(
          groupCode: list.groupCode,
          groupTitle: list.groupTitle,
        );
      }
    }
    
    // Sort by groupTitle alphabetically for consistent display
    final sortedGroups = groupMap.values.toList()
      ..sort((a, b) => a.groupTitle.compareTo(b.groupTitle));
    
    return sortedGroups;
  }
  
  /// Get distinct group codes for a section (legacy method for compatibility)
  /// @deprecated Use getGroupsBySection() which returns GroupInfo with titles
  @Deprecated('Use getGroupsBySection() which returns GroupInfo')
  List<String> getGroupCodesBySection(String sectionCode) {
    return getGroupsBySection(sectionCode).map((g) => g.groupCode).toList();
  }

  /// Get lists by section and group
  /// IMPORTANT: Filters by BOTH section_code AND group_code - no inference
  List<InterestList> getListsBySectionAndGroup(String sectionCode, String groupCode) {
    final result = _lists
        .where((list) => list.sectionCode == sectionCode && list.groupCode == groupCode)
        .toList();
    // Sort alphabetically by title for consistent display
    result.sort((a, b) => a.title.compareTo(b.title));
    return result;
  }

  /// Get items by list code (category code)
  List<Interest> getItemsByListCode(String listCode) {
    return _items.where((item) => item.listCodes.contains(listCode)).toList();
  }

  /// Get all items for a section
  List<Interest> getItemsBySection(String sectionCode) {
    final sectionLists = getListsBySection(sectionCode);
    final listCodes = sectionLists.map((list) => list.code).toSet();
    return _items.where((item) => item.listCodes.any((code) => listCodes.contains(code))).toList();
  }

  /// Get all items for a group
  List<Interest> getItemsByGroup(String sectionCode, String groupCode) {
    final groupLists = getListsBySectionAndGroup(sectionCode, groupCode);
    final listCodes = groupLists.map((list) => list.code).toSet();
    return _items.where((item) => item.listCodes.any((code) => listCodes.contains(code))).toList();
  }

  /// Load all catalog data from repository
  Future<void> loadCatalog({
    required Future<List<InterestSection>> Function() loadSections,
    required Future<List<InterestList>> Function() loadLists,
    required Future<List<Interest>> Function() loadItems,
  }) async {
    if (_isLoaded || _isLoading) {
      return; // Already loaded or loading
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load all data in parallel
      final results = await Future.wait([
        loadSections(),
        loadLists(),
        loadItems(),
      ]);

      _sections = results[0] as List<InterestSection>;
      _lists = results[1] as List<InterestList>;
      _items = results[2] as List<Interest>;

      _isLoaded = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Clear all data (useful for logout)
  void clear() {
    _sections = [];
    _lists = [];
    _items = [];
    _isLoaded = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

